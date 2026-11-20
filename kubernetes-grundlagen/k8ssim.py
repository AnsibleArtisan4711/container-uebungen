#!/usr/bin/env python3
"""k8ssim.py - einfaches MODELL eines Kubernetes-Clusters für die Übungen (P26). Es ist KEIN Kubernetes und KEIN kubectl.
Echt ist nur die Prüfung der Manifeste gegen die Schemas von Kubernetes (Paket kubernetes-validate). Alles andere (Steuerung,
Planung, Dienste, Ingress, Rechte) bildet vereinfachte Regeln nach. Zeit gibt es nicht: Alter und Uhrzeiten werden nicht ausgegeben.
Zustand: Datei $K8S_STATE (Vorgabe /tmp/p26/state.json)."""
import sys, os, json, math, hashlib, base64, subprocess, argparse

ST = os.environ.get('K8S_STATE', '/tmp/p26/state.json')
SCHEMA_VERSION = os.environ.get('K8S_VERSION', '1.31')
BADIMG = ('doesnotexist', 'nicht-vorhanden', 'missing')

def load():
    return json.load(open(ST))
def save(s):
    os.makedirs(os.path.dirname(ST), exist_ok=True); json.dump(s, open(ST, 'w'), indent=1, sort_keys=True)
def h(txt, n):
    return hashlib.md5(txt.encode()).hexdigest()[:n]
def die(msg):
    print(msg); sys.exit(1)
def objs(s, ns, kind):
    return s['objs'].setdefault(ns, {}).setdefault(kind, {})
def short(kind):
    return {'Deployment': 'deployment.apps', 'Service': 'service', 'ConfigMap': 'configmap', 'Secret': 'secret', 'Ingress': 'ingress.networking.k8s.io',
            'Role': 'role.rbac.authorization.k8s.io', 'RoleBinding': 'rolebinding.rbac.authorization.k8s.io', 'ServiceAccount': 'serviceaccount',
            'Namespace': 'namespace', 'ClusterRole': 'clusterrole.rbac.authorization.k8s.io', 'ClusterRoleBinding': 'clusterrolebinding.rbac.authorization.k8s.io',
            'Pod': 'pod', 'PersistentVolumeClaim': 'persistentvolumeclaim'}.get(kind, kind.lower())
def cpu_m(v):
    v = str(v); return int(v[:-1]) if v.endswith('m') else int(float(v) * 1000)
def mem_mi(v):
    v = str(v)
    for suf, f in (('Gi', 1024), ('Mi', 1), ('Ki', 1 / 1024)):
        if v.endswith(suf): return int(float(v[:-2]) * f)
    return int(v) // (1024 * 1024)

def validate(doc, fname):
    r = subprocess.run(['kubernetes-validate', '-k', SCHEMA_VERSION, '--strict', '--quiet', fname], capture_output=True, text=True)
    return r

# ---------- Controller ----------
def pod_ready(p): return p['phase'] == 'Running'
def image_bad(img): return any(b in img for b in BADIMG)
def alloc(s, node):
    used_c = used_m = 0
    for ns, pods in s['pods'].items():
        for p in pods.values():
            if p['node'] == node: used_c += p['cpu']; used_m += p['mem']
    return used_c, used_m
def schedule(s, p):
    cands = []
    for n, nd in sorted(s['nodes'].items()):
        if not nd['ready'] or nd['unsched'] or nd['role'] == 'control-plane': continue   # Control-Plane-Knoten tragen eine Taint
        uc, um = alloc(s, n)
        if uc + p['cpu'] > nd['cpu'] or um + p['mem'] > nd['mem']: continue
        cnt = sum(1 for ns in s['pods'].values() for q in ns.values() if q['node'] == n)
        cands.append((cnt, n))
    if not cands:
        total = len(s['nodes'])
        why = 'Insufficient cpu' if p['cpu'] else 'no node available'
        p['node'] = ''; p['phase'] = 'Pending'; p['reason'] = 'Unschedulable'
        p['events'] = ['Warning FailedScheduling 0/%d nodes are available: %d %s.' % (total, total, why)]; return
    node = sorted(cands)[0][1]; p['node'] = node
    p['events'] = ['Normal Scheduled Successfully assigned %s/%s to %s' % (p['ns'], p['name'], node)]
    if image_bad(p['image']):
        p['phase'] = 'Pending'; p['reason'] = 'ImagePullBackOff'
        p['events'] += ['Normal Pulling Pulling image "%s"' % p['image'], 'Warning Failed Failed to pull image "%s": not found' % p['image'], 'Warning Failed Error: ImagePullBackOff']
    else:
        p['phase'] = 'Running'; p['reason'] = ''
        p['events'] += ['Normal Pulling Pulling image "%s"' % p['image'], 'Normal Pulled Successfully pulled image "%s"' % p['image'], 'Normal Started Started container']
def new_pod(s, rs, ns):
    s['seq'] += 1
    t = rs['template']; c = t['spec']['containers'][0]
    res = c.get('resources', {}).get('requests', {})
    p = dict(name='%s-%s' % (rs['name'], h('%s%d' % (rs['name'], s['seq']), 5)), ns=ns, owner=rs['name'], labels=t['metadata'].get('labels', {}),
             image=c['image'], cpu=cpu_m(res.get('cpu', 0)), mem=mem_mi(res.get('memory', 0)), node='', phase='Pending', reason='', events=[],
             env=c.get('env', []), envFrom=c.get('envFrom', []), volumes=t['spec'].get('volumes', []))
    schedule(s, p); s['pods'].setdefault(ns, {})[p['name']] = p
def reconcile_rs(s, ns):
    pods = s['pods'].setdefault(ns, {})
    for n in [n for n, p in pods.items() if p['node'] and not s['nodes'][p['node']]['ready']]:
        del pods[n]   # Modell: Pods eines ausgefallenen Knotens gelten sofort als verloren
    for rs in objs(s, ns, 'ReplicaSet').values():
        mine = sorted(n for n, p in pods.items() if p['owner'] == rs['name'])
        while len(mine) > rs['replicas']:   # überzählige: zuerst nicht bereite, dann alphabetisch letzte
            mine.sort(key=lambda n: (pod_ready(pods[n]), n)); del pods[mine.pop(0)]
        while len(mine) < rs['replicas']:
            new_pod(s, rs, ns); mine = sorted(n for n, p in pods.items() if p['owner'] == rs['name'])
    for n in [n for n, p in pods.items() if p['owner'] not in objs(s, ns, 'ReplicaSet') or objs(s, ns, 'ReplicaSet')[p['owner']]['replicas'] == 0]:
        if pods[n]['owner'] in objs(s, ns, 'ReplicaSet') or pods[n]['owner'] == '': del pods[n]
def retry_pending(s):
    for ns, pods in s['pods'].items():
        for p in pods.values():
            if p['phase'] == 'Pending' and p['reason'] == 'Unschedulable': schedule(s, p)
def reconcile_all(s):
    for ns in list(s['objs']):
        reconcile_rs(s, ns)
    retry_pending(s)
def template_hash(t): return h(json.dumps(t, sort_keys=True), 10)
def rollout(s, ns, dep, log):
    """Rolling Update: neues ReplicaSet hoch, altes herunter (maxSurge/maxUnavailable)."""
    spec = dep['spec']; D = spec.get('replicas', 1); t = spec['template']
    strat = spec.get('strategy', {}).get('rollingUpdate', {})
    def val(v, d, up): 
        v = strat.get(v, d)
        if isinstance(v, str) and v.endswith('%'): x = D * int(v[:-1]) / 100; return math.ceil(x) if up else math.floor(x)
        return int(v)
    surge = val('maxSurge', '25%', True); unav = val('maxUnavailable', '25%', False)
    if surge == 0 and unav == 0: unav = 1
    rsd = objs(s, ns, 'ReplicaSet'); name = '%s-%s' % (dep['metadata']['name'], template_hash(t))
    mine = [r for r in rsd.values() if r['deployment'] == dep['metadata']['name']]
    if name not in rsd:
        s['rev'][ns + '/' + dep['metadata']['name']] = s['rev'].get(ns + '/' + dep['metadata']['name'], 0) + 1
        rsd[name] = dict(name=name, deployment=dep['metadata']['name'], template=t, replicas=0, revision=s['rev'][ns + '/' + dep['metadata']['name']])
    elif rsd[name]['revision'] != max(r['revision'] for r in mine):   # Rückkehr zu einer älteren Vorlage: neue Revisionsnummer
        s['rev'][ns + '/' + dep['metadata']['name']] += 1; rsd[name]['revision'] = s['rev'][ns + '/' + dep['metadata']['name']]
    new = rsd[name]; olds = [r for r in rsd.values() if r['deployment'] == dep['metadata']['name'] and r['name'] != name]
    pods = s['pods'].setdefault(ns, {})
    def ready_new(): return sum(1 for p in pods.values() if p['owner'] == name and pod_ready(p))
    def ready_old(): return sum(1 for p in pods.values() if p['owner'] in [o['name'] for o in olds] and pod_ready(p))
    step = 0
    while True:
        step += 1; before = (new['replicas'], [o['replicas'] for o in olds])
        total = new['replicas'] + sum(o['replicas'] for o in olds)
        for o in olds:   # nicht bereite Pods alter ReplicaSets zuerst entfernen (unabhängig von der Verfügbarkeit)
            unh = sum(1 for p in pods.values() if p['owner'] == o['name'] and not pod_ready(p))
            o['replicas'] = max(0, o['replicas'] - unh)
        reconcile_rs(s, ns)
        total = new['replicas'] + sum(o['replicas'] for o in olds)
        up = min(D - new['replicas'], D + surge - total)
        if up > 0: new['replicas'] += up; reconcile_rs(s, ns)
        avail = ready_new() + ready_old()
        down = max(0, avail - (D - unav))
        for o in sorted(olds, key=lambda r: r['name']):
            d = min(o['replicas'], down); o['replicas'] -= d; down -= d
        reconcile_rs(s, ns)
        log.append('Schritt %d: neues ReplicaSet %d, altes %d (bereit: neu %d, alt %d)' % (step, new['replicas'], sum(o['replicas'] for o in olds), ready_new(), ready_old()))
        after = (new['replicas'], [o['replicas'] for o in olds])
        if after == before or (new['replicas'] == D and sum(o['replicas'] for o in olds) == 0): break
    return new['replicas'] == D and sum(o['replicas'] for o in olds) == 0 and ready_new() == D

def deploy_state(s, ns, d):
    rs = [r for r in objs(s, ns, 'ReplicaSet').values() if r['deployment'] == d['metadata']['name'] and r['replicas'] > 0]
    pods = [p for p in s['pods'].get(ns, {}).values() if p['owner'] in [r['name'] for r in rs]]
    return sum(1 for p in pods if pod_ready(p)), d['spec'].get('replicas', 1), len(pods)

# ---------- Befehle ----------
def cmd_init(a):
    nodes = {}
    for i, n in enumerate(a.nodes.split(',')):
        nodes[n] = dict(ready=True, unsched=False, cpu=2000, mem=4096, role='control-plane' if i == 0 else 'worker')
    s = dict(nodes=nodes, objs={'default': {}, 'kube-system': {}}, pods={}, seq=0, rev={}, rr={})
    save(s); print('Modell-Cluster mit %d Knoten angelegt (je 2 CPU, 4096 MiB); Namespaces: default, kube-system' % len(nodes))
def split_docs(fname):
    import yaml
    return [d for d in yaml.safe_load_all(open(fname)) if d]
def cmd_apply(a):
    s = load(); docs = split_docs(a.f)
    r = validate(docs, a.f)
    if r.returncode != 0:
        for l in r.stdout.splitlines() + r.stderr.splitlines():
            if l.startswith('ERROR'): print(l.replace(a.f, os.path.basename(a.f)))
        die('Fehler: Manifest ungültig, nichts angewendet (Prüfung gegen Schema %s)' % SCHEMA_VERSION)
    for d in docs:
        kind = d['kind']; name = d['metadata']['name']; ns = a.n or d['metadata'].get('namespace', 'default')
        if kind in ('Namespace', 'ClusterRole', 'ClusterRoleBinding'): ns = '_cluster'
        elif ns not in s['objs'] or (ns != '_cluster' and 'Namespace' not in s['objs'].get('_cluster', {}) and ns not in ('default', 'kube-system') and ns not in s['objs']):
            die('Fehler: Namespace "%s" nicht gefunden' % ns)
        if kind == 'Namespace': s['objs'].setdefault(name, {})
        store = objs(s, ns, kind); old = store.get(name)
        status = 'created' if old is None else ('unchanged' if old == d else 'configured')
        store[name] = d
        if kind == 'Deployment' and status != 'unchanged':
            log = []; ok = rollout(s, ns, d, log)
            s.setdefault('last_rollout', {})[ns + '/' + name] = log
        print('%s/%s %s' % (short(kind), name, status))
    reconcile_all(s); save(s)
def fmt_table(rows, head):
    cols = list(zip(*([head] + rows))) if rows else [[x] for x in head]
    w = [max(len(str(x)) for x in c) for c in cols]
    for r in [head] + rows: print('  '.join(str(x).ljust(w[i]) for i, x in enumerate(r)).rstrip())
def cmd_get(a):
    s = load(); ns = a.n or 'default'; res = a.res
    if res in ('nodes', 'node'):
        rows = [[n, ('Ready' if d['ready'] else 'NotReady') + (',SchedulingDisabled' if d['unsched'] else ''), d['role']] for n, d in sorted(s['nodes'].items())]
        fmt_table(rows, ['NAME', 'STATUS', 'ROLES']); return
    if res in ('ns', 'namespaces'):
        for n in sorted(k for k in s['objs'] if k != '_cluster'): print(n)
        return
    if res in ('pods', 'pod', 'po'):
        pods = sorted(s['pods'].get(ns, {}).values(), key=lambda p: p['name'])
        if a.l: k, v = a.l.split('='); pods = [p for p in pods if p['labels'].get(k) == v]
        rows = [[p['name'], '1/1' if pod_ready(p) else '0/1', p['reason'] or p['phase'], p['node'] or '<none>'] for p in pods]
        if not rows: print('No resources found in %s namespace.' % ns); return
        fmt_table(rows, ['NAME', 'READY', 'STATUS', 'NODE']); return
    if res in ('deploy', 'deployment', 'deployments'):
        rows = []
        for n, d in sorted(objs(s, ns, 'Deployment').items()):
            r, D, tot = deploy_state(s, ns, d); rows.append([n, '%d/%d' % (r, D), r, d['spec']['template']['spec']['containers'][0]['image']])
        fmt_table(rows, ['NAME', 'READY', 'AVAILABLE', 'IMAGE']); return
    if res in ('rs', 'replicaset', 'replicasets'):
        rows = [[n, r['replicas'], sum(1 for p in s['pods'].get(ns, {}).values() if p['owner'] == n and pod_ready(p)), r['revision']] for n, r in sorted(objs(s, ns, 'ReplicaSet').items())]
        fmt_table(rows, ['NAME', 'DESIRED', 'READY', 'REVISION']); return
    if res in ('svc', 'service', 'services'):
        rows = [[n, d['spec'].get('type', 'ClusterIP'), svc_ip(s, ns, n), ','.join('%s/TCP' % p['port'] for p in d['spec']['ports'])] for n, d in sorted(objs(s, ns, 'Service').items())]
        fmt_table(rows, ['NAME', 'TYPE', 'CLUSTER-IP', 'PORT(S)']); return
    if res in ('endpoints', 'ep'):
        rows = [[n, ','.join('%s:%s' % (pod_ip(p), pt['targetPort']) for p in endpoints(s, ns, d) for pt in d['spec']['ports'][:1]) or '<none>'] for n, d in sorted(objs(s, ns, 'Service').items())]
        fmt_table(rows, ['NAME', 'ENDPOINTS']); return
    if res in ('cm', 'configmap', 'configmaps'):
        fmt_table([[n, len(d.get('data', {}))] for n, d in sorted(objs(s, ns, 'ConfigMap').items())], ['NAME', 'DATA']); return
    if res in ('secret', 'secrets'):
        fmt_table([[n, d.get('type', 'Opaque'), len(d.get('data', {})) + len(d.get('stringData', {}))] for n, d in sorted(objs(s, ns, 'Secret').items())], ['NAME', 'TYPE', 'DATA']); return
    if res in ('ingress', 'ing'):
        fmt_table([[n, ','.join(r['host'] for r in d['spec']['rules'])] for n, d in sorted(objs(s, ns, 'Ingress').items())], ['NAME', 'HOSTS']); return
    die('Fehler: Ressourcentyp "%s" im Modell nicht bekannt' % res)
def pod_ip(p): return '10.244.%d.%d' % (int(h(p['name'], 2), 16) % 4 + 1, int(h(p['name'], 4), 16) % 200 + 10)
def svc_ip(s, ns, n): return '10.96.%d.%d' % (int(h(ns + n, 2), 16) % 200, int(h(n + ns, 2), 16) % 200 + 1)
def endpoints(s, ns, svc):
    sel = svc['spec'].get('selector', {})
    return [p for p in sorted(s['pods'].get(ns, {}).values(), key=lambda p: p['name']) if pod_ready(p) and sel and all(p['labels'].get(k) == v for k, v in sel.items())]
def cmd_scale(a):
    s = load(); ns = a.n or 'default'; kind, name = a.res.split('/'); d = objs(s, ns, 'Deployment').get(name)
    if not d: die('Fehler: deployment "%s" nicht gefunden' % name)
    d['spec']['replicas'] = a.replicas
    rs = [r for r in objs(s, ns, 'ReplicaSet').values() if r['deployment'] == name and r['name'].endswith(template_hash(d['spec']['template']))][0]
    rs['replicas'] = a.replicas; reconcile_all(s); save(s); print('deployment.apps/%s scaled' % name)
def cmd_delete(a):
    s = load(); ns = a.n or 'default'; kind, name = a.res.split('/')
    if kind == 'pod':
        if name not in s['pods'].get(ns, {}): die('Fehler: pod "%s" nicht gefunden' % name)
        del s['pods'][ns][name]; reconcile_all(s); save(s); print('pod "%s" deleted' % name)
    elif kind in ('deploy', 'deployment'):
        objs(s, ns, 'Deployment').pop(name, None)
        for rn in [r for r, v in objs(s, ns, 'ReplicaSet').items() if v['deployment'] == name]: del objs(s, ns, 'ReplicaSet')[rn]
        reconcile_all(s); save(s); print('deployment.apps "%s" deleted' % name)
    elif kind in ('ns', 'namespace'):
        s['objs'].pop(name, None); s['pods'].pop(name, None); s['objs'].get('_cluster', {}).get('Namespace', {}).pop(name, None); save(s); print('namespace "%s" deleted' % name)
    else:
        objs(s, ns, kind.capitalize() if kind != 'svc' else 'Service').pop(name, None); save(s); print('%s "%s" deleted' % (kind, name))
def cmd_set_image(a):
    s = load(); ns = a.n or 'default'; kind, name = a.res.split('/'); d = objs(s, ns, 'Deployment').get(name)
    if not d: die('Fehler: deployment "%s" nicht gefunden' % name)
    c, img = a.assign.split('=')
    for cc in d['spec']['template']['spec']['containers']:
        if cc['name'] == c: cc['image'] = img
    log = []; rollout(s, ns, d, log)
    for l in log: print(l)
    save(s); print('deployment.apps/%s image updated' % name)
def cmd_rollout(a):
    s = load(); ns = a.n or 'default'; kind, name = a.res.split('/'); d = objs(s, ns, 'Deployment').get(name)
    if not d: die('Fehler: deployment "%s" nicht gefunden' % name)
    if a.action == 'status':
        r, D, tot = deploy_state(s, ns, d)
        newrs = [r_ for r_ in objs(s, ns, 'ReplicaSet').values() if r_['deployment'] == name and r_['revision'] == max(x['revision'] for x in objs(s, ns, 'ReplicaSet').values() if x['deployment'] == name)][0]
        nr = sum(1 for p in s['pods'].get(ns, {}).values() if p['owner'] == newrs['name'] and pod_ready(p))
        print('Rollout von "%s" abgeschlossen: %d von %d neuen Pods bereit' % (name, nr, D) if nr == D and tot == D else 'Rollout von "%s" nicht abgeschlossen: %d von %d neuen Pods bereit, %d Pods insgesamt bereit' % (name, nr, D, r))
    elif a.action == 'history':
        rows = sorted([[r['revision'], r['template']['spec']['containers'][0]['image']] for r in objs(s, ns, 'ReplicaSet').values() if r['deployment'] == name])
        fmt_table(rows, ['REVISION', 'IMAGE'])
    elif a.action == 'undo':
        rsd = sorted([r for r in objs(s, ns, 'ReplicaSet').values() if r['deployment'] == name], key=lambda r: r['revision'])
        cur = max(rsd, key=lambda r: r['revision']); prev = [r for r in rsd if r['revision'] < cur['revision']]
        if not prev: die('Fehler: keine frühere Revision')
        target = prev[-1]; d['spec']['template'] = target['template']
        log = []; rollout(s, ns, d, log)
        for l in log: print(l)
        save(s); print('deployment.apps/%s rolled back' % name)
def cmd_describe(a):
    s = load(); ns = a.n or 'default'; p = s['pods'].get(ns, {}).get(a.name)
    if not p: die('Fehler: pod "%s" nicht gefunden' % a.name)
    print('Name: %s\nNode: %s\nStatus: %s\nImage: %s\nEvents:' % (p['name'], p['node'] or '<none>', p['reason'] or p['phase'], p['image']))
    for e in p['events']: print('  ' + e)
def cmd_node(a):
    s = load()
    if a.node not in s['nodes']: die('Fehler: node "%s" nicht gefunden' % a.node)
    nd = s['nodes'][a.node]
    if a.action == 'cordon': nd['unsched'] = True; print('node/%s cordoned' % a.node)
    elif a.action == 'uncordon': nd['unsched'] = False; print('node/%s uncordoned' % a.node)
    elif a.action == 'drain':
        nd['unsched'] = True
        for ns, pods in s['pods'].items():
            for n in [n for n, p in pods.items() if p['node'] == a.node]: del pods[n]
        print('node/%s drained' % a.node)
    elif a.action == 'fail': nd['ready'] = False; print('node/%s ausgefallen (NotReady)' % a.node)
    elif a.action == 'recover': nd['ready'] = True; nd['unsched'] = False; print('node/%s wieder Ready' % a.node)
    reconcile_all(s); save(s)
def cmd_curl(a):
    s = load(); ns = a.n or 'default'; svc = objs(s, ns, 'Service').get(a.svc)
    if not svc: print('curl: Could not resolve host: %s' % a.svc); sys.exit(6)
    ep = endpoints(s, ns, svc)
    if not ep: print('curl: Connection refused (Service %s hat keine Endpunkte)' % a.svc); sys.exit(7)
    key = ns + '/' + a.svc; i = s['rr'].get(key, 0); s['rr'][key] = i + 1; save(s)
    print('Antwort von %s' % ep[i % len(ep)]['name'])
def cmd_env(a):
    s = load(); ns = a.n or 'default'; p = s['pods'].get(ns, {}).get(a.pod)
    if not p: die('Fehler: pod "%s" nicht gefunden' % a.pod)
    for e in p['env']:
        if 'value' in e: print('%s=%s' % (e['name'], e['value']))
        elif 'valueFrom' in e:
            ref = e['valueFrom'].get('configMapKeyRef') or e['valueFrom'].get('secretKeyRef'); kind = 'ConfigMap' if 'configMapKeyRef' in e['valueFrom'] else 'Secret'
            o = objs(s, ns, kind).get(ref['name'])
            if o is None: print('%s=<Fehler: %s "%s" nicht gefunden>' % (e['name'], kind, ref['name'])); continue
            v = o.get('data', {}).get(ref['key'])
            if v is not None and kind == 'Secret': v = base64.b64decode(v).decode()
            if v is None and kind == 'Secret': v = o.get('stringData', {}).get(ref['key'])
            print('%s=%s' % (e['name'], v))
def cmd_route(a):
    s = load(); best = None
    for ns in s['objs']:
        if ns == '_cluster': continue
        for ing in objs(s, ns, 'Ingress').values():
            for r in ing['spec']['rules']:
                if r['host'] != a.host: continue
                for pa in r['http']['paths']:
                    pt = pa.get('pathType', 'Prefix'); path = pa['path']
                    ok = (a.path == path) if pt == 'Exact' else (a.path == path or a.path.startswith(path.rstrip('/') + '/') or path == '/')
                    if ok and (best is None or len(path) > len(best[1])): best = (ns, path, pa['backend']['service'], ing['metadata']['name'])
    if not best: print('404 Not Found (keine Regel für %s%s)' % (a.host, a.path)); sys.exit(4)
    svc = objs(s, best[0], 'Service').get(best[2]['name'])
    if not svc: print('503 Service Unavailable (Dienst %s fehlt)' % best[2]['name']); sys.exit(5)
    print('%s%s -> Ingress %s -> Dienst %s/%s (Port %s)' % (a.host, a.path, best[3], best[0], best[2]['name'], best[2]['port']['number']))
def cmd_can(a):
    s = load(); ns = a.n or 'default'; user = a.user
    rules = []
    def add(role_name, role_kind, bns):
        r = objs(s, bns, 'Role').get(role_name) if role_kind == 'Role' else objs(s, '_cluster', 'ClusterRole').get(role_name)
        if r:
            for ru in r.get('rules', []): rules.append((ru, bns))
    for bns in [ns]:
        for rb in objs(s, bns, 'RoleBinding').values():
            if any(sb['kind'] in ('User', 'ServiceAccount') and (sb['name'] == user or ('system:serviceaccount:%s:%s' % (sb.get('namespace', bns), sb['name'])) == user) for sb in rb.get('subjects', [])):
                add(rb['roleRef']['name'], rb['roleRef']['kind'], bns)
    for crb in objs(s, '_cluster', 'ClusterRoleBinding').values():
        if any(sb['name'] == user for sb in crb.get('subjects', [])): add(crb['roleRef']['name'], 'ClusterRole', ns)
    res, _, sub = a.resource.partition('/')
    for ru, bns in rules:
        if a.verb in ru.get('verbs', []) + (['*'] if '*' in ru.get('verbs', []) else []) or '*' in ru.get('verbs', []):
            if res in ru.get('resources', []) or '*' in ru.get('resources', []):
                print('yes'); return
    print('no'); sys.exit(1)

def main():
    p = argparse.ArgumentParser(); sub = p.add_subparsers(dest='c', required=True)
    x = sub.add_parser('init'); x.add_argument('--nodes', default='cp1,w1,w2'); x.set_defaults(f_=cmd_init)
    x = sub.add_parser('apply'); x.add_argument('-f', required=True); x.add_argument('-n'); x.set_defaults(f_=cmd_apply)
    x = sub.add_parser('get'); x.add_argument('res'); x.add_argument('-n'); x.add_argument('-l'); x.set_defaults(f_=cmd_get)
    x = sub.add_parser('scale'); x.add_argument('res'); x.add_argument('--replicas', type=int, required=True); x.add_argument('-n'); x.set_defaults(f_=cmd_scale)
    x = sub.add_parser('delete'); x.add_argument('res'); x.add_argument('-n'); x.set_defaults(f_=cmd_delete)
    x = sub.add_parser('set-image'); x.add_argument('res'); x.add_argument('assign'); x.add_argument('-n'); x.set_defaults(f_=cmd_set_image)
    x = sub.add_parser('rollout'); x.add_argument('action', choices=['status', 'history', 'undo']); x.add_argument('res'); x.add_argument('-n'); x.set_defaults(f_=cmd_rollout)
    x = sub.add_parser('describe'); x.add_argument('name'); x.add_argument('-n'); x.set_defaults(f_=cmd_describe)
    x = sub.add_parser('node'); x.add_argument('action', choices=['cordon', 'uncordon', 'drain', 'fail', 'recover']); x.add_argument('node'); x.set_defaults(f_=cmd_node)
    x = sub.add_parser('curl'); x.add_argument('svc'); x.add_argument('-n'); x.set_defaults(f_=cmd_curl)
    x = sub.add_parser('env'); x.add_argument('pod'); x.add_argument('-n'); x.set_defaults(f_=cmd_env)
    x = sub.add_parser('route'); x.add_argument('host'); x.add_argument('path'); x.set_defaults(f_=cmd_route)
    x = sub.add_parser('can-i'); x.add_argument('verb'); x.add_argument('resource'); x.add_argument('--as', dest='user', required=True); x.add_argument('-n'); x.set_defaults(f_=cmd_can)
    a = p.parse_args(); a.f_(a)
main()
