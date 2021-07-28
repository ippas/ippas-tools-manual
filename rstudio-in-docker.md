Uruchom kontener _in detached mode_ `-d`, na porcie `-p` (zewnętrzny, możemy sobie wybrać) 8989:8787 (wewnętrzny, stały). Użytkownik niech się nazywa `user`, a hasło `pass`. Będzie on miał uprawnienia takie jak użytkownik `1005` i grupa `1002` na hoście. Wartości te możemy sprawdzić dla siebie komendą `id`. Tworzone pliki będą _writable_ dla właściciela i grupy (UMASK).

```bash
docker run -d -p <port>:8787 -e USER=user -e USERID=$(id | grep -o -P "uid=\d+" | cut -d '=' -f2) -e GROUPID=1002 -e UMASK=002 -e PASSWORD=pass -v /home/ifpan/projects/:/projects --name my-container-name rocker/verse:4.1.0
```

Tunel:

```bash
ssh user@server -fNL <local_port>:localhost:<remote_port>
```
`fN` - just forward and go to background, don't login to server
`L` - tunel
