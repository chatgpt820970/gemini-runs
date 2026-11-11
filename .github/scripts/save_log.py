# Save the run log into the PRIVATE code repo (never into the public runner logs).
import base64, json, os, sys, urllib.request, urllib.error
src, dest = sys.argv[1], sys.argv[2]
repo, token = os.environ["CODE_REPO"], os.environ["GH_TOKEN"]
url = f"https://api.github.com/repos/{repo}/contents/{dest}"
hdr = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
sha = None
try:
    with urllib.request.urlopen(urllib.request.Request(url, headers=hdr)) as r:
        sha = json.load(r).get("sha")
except urllib.error.HTTPError:
    pass
body = {"message": "run log", "content": base64.b64encode(open(src, "rb").read()).decode()}
if sha:
    body["sha"] = sha
req = urllib.request.Request(url, data=json.dumps(body).encode(), headers=hdr, method="PUT")
urllib.request.urlopen(req).read()
