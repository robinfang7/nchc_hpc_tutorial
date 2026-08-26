# 在晶創26開啟Jupyter Notebook

1. 晶創26有5台登入節點，每次登入晶創26會隨機進入某台登入節點，因此要查詢登入節點的IP。  
```bash
[u8880716@25a-lgn02 ~]$ curl ip.me
140.110.x.x
```

引用Jupyter Notebook模組  
```bash
[u8880716@25a-lgn02 ~]$ module load jupyter/jupyterlab
```

啟動jupyter notebook  
```bash
[u8880716@25a-lgn02 ~]$ jupyter notebook --no-browser --port=9999
[I 2026-08-18 15:50:11.434 ServerApp] Extension package jupyter_lsp took 0.1480s to import
[I 2026-08-18 15:50:12.163 ServerApp] jupyter_lsp | extension was successfully linked.
[I 2026-08-18 15:50:12.167 ServerApp] jupyter_server_terminals | extension was successfully linked.
[I 2026-08-18 15:50:12.170 ServerApp] jupyterlab | extension was successfully linked.
[I 2026-08-18 15:50:12.173 ServerApp] notebook | extension was successfully linked.
[I 2026-08-18 15:50:13.815 ServerApp] notebook_shim | extension was successfully linked.
[I 2026-08-18 15:50:13.891 ServerApp] notebook_shim | extension was successfully loaded.
[I 2026-08-18 15:50:13.892 ServerApp] jupyter_lsp | extension was successfully loaded.
[I 2026-08-18 15:50:13.893 ServerApp] jupyter_server_terminals | extension was successfully loaded.
[I 2026-08-18 15:50:13.917 LabApp] JupyterLab extension loaded from /work/envstack/apps/jupyter/lib/python3.14/site-packages/jupyterlab
[I 2026-08-18 15:50:13.917 LabApp] JupyterLab application directory is /work/envstack/apps/jupyter/share/jupyter/lab
[I 2026-08-18 15:50:13.918 LabApp] Extension Manager is 'pypi'.
[I 2026-08-18 15:50:14.117 ServerApp] jupyterlab | extension was successfully loaded.
[I 2026-08-18 15:50:14.125 ServerApp] notebook | extension was successfully loaded.
[I 2026-08-18 15:50:14.125 ServerApp] Serving notebooks from local directory: /home/u8880716
[I 2026-08-18 15:50:14.125 ServerApp] Jupyter Server 2.18.2 is running at:
[I 2026-08-18 15:50:14.125 ServerApp] http://localhost:9999/tree?token=293927b61c749274ee4683450b831b526f1bf90c82374528
[I 2026-08-18 15:50:14.125 ServerApp]     http://127.0.0.1:9999/tree?token=293927b61c749274ee4683450b831b526f1bf90c82374528
[I 2026-08-18 15:50:14.125 ServerApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 2026-08-18 15:50:14.132 ServerApp]

    To access the server, open this file in a browser:
        file:/home/u8880716/.jupyter/runtime/jpserver-3933330-open.html
    Or copy and paste one of these URLs:
        http://localhost:9999/tree?token=293927b61c749274ee4683450b831b526f1bf90c82374528
        http://127.0.0.1:9999/tree?token=293927b61c749274ee4683450b831b526f1bf90c82374528
[I 2026-08-18 15:50:14.291 ServerApp] Skipped non-installed server(s): basedpyright, bash-language-server, dockerfile-language-server-nodejs, javascript-typescript-langserver, jedi-language-server, julia-language-server, pyrefly, pyright, python-language-server, python-lsp-server, r-languageserver, sql-language-server, texlab, typescript-language-server, unified-language-server, vscode-css-languageserver-bin, vscode-html-languageserver-bin, vscode-json-languageserver-bin, yaml-language-server
```
此畫面表示已開啟jupyter notebook，預先複製`http://localhost:9999/tree?token=293927b61c749274ee4683450b831b526f1bf90c82374528`  
token是隨機值。  

2. 到本地端電腦的終端機或Powershell，輸入`ssh -N -f -L 9999:localhost:9999 u8880716@140.110.x.x`  
```bash
PS C:\Users\ybfang> ssh -N -f -L 9999:localhost:9999 u8880716@140.110.x.x
The authenticity of host '140.110.x.x (140.110.x.x)' can't be established.
This host key is known by the following other names/addresses:
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '140.110.x.x' (ED25519) to the list of known hosts.
(u8880716@140.110.x.x) Please select the 2FA login method.
1. Mobile APP OTP
2. Mobile APP PUSH
3. Email OTP
Login method: 2
(u8880716@140.110.x.x) Password:
Please check your push token.
[PASS] The push verification succeeded.
```
`-L 9999:localhost:9999：`將你個人電腦的 9999 port，轉發到登入節點的 9999 port。  
`-N -f`：讓這個 SSH 連線在背景執行，不開啟遠端終端機。  

3. 開啟本地端電腦的網頁瀏覽器，在URL輸入`http://localhost:9999/tree?token=293927b61c749274ee4683450b831b526f1bf90c82374528`  

![JupyterNotebook](https://cdn.phototourl.com/free/2026-08-21-e2fbc8f7-d31e-4f19-b5e8-a6b4f7350672.png)

4. 不要用Jupyter Notebook進行計算，使用登入節點計算。  
