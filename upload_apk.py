import urllib.request, json, os, datetime

TOKEN = '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'
REPO = 'XDKILLER4388/Zenshi'
APK = r'C:\Zenshi\build\app\outputs\flutter-apk\app-release.apk'

# Use timestamp for unique tags
now = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
TAG = f'v1.1.0-{now}'

headers_json = {
    'Authorization': f'token {TOKEN}',
    'Content-Type': 'application/json',
    'Accept': 'application/vnd.github.v3+json',
}

body = json.dumps({
    'tag_name': TAG,
    'name': f'Zenshi {TAG} - Update',
    'body': 'Automated build and update.\n\n- Fixed NSFW content filtering\n- Improved Manhua visibility\n- Filtered empty chapters\n- Added Doki and Manhwa18 sources to marketplace',
    'draft': False,
    'prerelease': False,
}).encode()

req = urllib.request.Request(
    f'https://api.github.com/repos/{REPO}/releases',
    data=body, method='POST', headers=headers_json
)
with urllib.request.urlopen(req) as r:
    release = json.loads(r.read())

release_id = release['id']
print(f'Release: {release_id}')

with open(APK, 'rb') as f:
    apk_data = f.read()

print(f'Uploading {len(apk_data)/1024/1024:.1f} MB...')

upload_req = urllib.request.Request(
    f'https://uploads.github.com/repos/{REPO}/releases/{release_id}/assets?name=zenshi-{TAG}.apk',
    data=apk_data, method='POST',
    headers={
        'Authorization': f'token {TOKEN}',
        'Content-Type': 'application/vnd.android.package-archive',
    }
)
with urllib.request.urlopen(upload_req, timeout=300) as r:
    result = json.loads(r.read())
    print('DONE:', result['browser_download_url'])
