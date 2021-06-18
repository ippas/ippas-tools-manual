## Singularity
Ciekawy [tutorial](https://singularity-tutorial.github.io)  
[Inny](https://carpentries-incubator.github.io/singularity-introduction/) mniej ciekawy.

## Spis treści
* [Różnica z dokerem](#docker)
* [Pobieranie obrazów](#pull)
* [Uruchamianie kontenerów](#run)
* [Budowanie kontenerów](#build)
* [Tagi i konwencje nazewnicze](#tags)
* [Bezpieczeństwo](#safety)
* [Podpinanie katalogów](#bind)
* [Long-running Instances](#instances)
* [Faking a Native Installation within a Singularity Container](#fakeinstall)
* [Misc](#misc)



### <a name="docker">Różnica z dokerem</a>

1. [Brak potrzeby dostępu do roota i slurm może łatwo ograniczać zasoby (alokować).](https://www.reddit.com/r/docker/comments/7y2yp2/why_is_singularity_used_as_opposed_to_docker_in/)

2. Docker tworzy pliki jako root i działa jako root, a nie użytkownik (user id -> root). Można to obejść:
```
$ docker run -u "$(id -u):$(id -g)" \
    -v $PWD:/data -w /data itamarst/dataprocessor \
    input.txt output.txt
```
W Singularity kontenery są uruchamiane jako użytkownik automatycznie.

3. Docker images are stored off in the local image cache, and you’re expected to interact with them using the `docker image` command, e.g. `docker image ls`. In contrast, Singularity images are just normal files on your filesystem (SIF files - Singularity Image Format).

4. Singularity stworzone z myślą o HPC (High-performance computing).


### <a name="pull">Pobieranie obrazów</a>

Skąd można pobierać obrazy:
- `library://` - [official image registry provided by Sylabs.io](https://cloud.sylabs.io/library)
- `docker://` - docker hub
- `shub://` - [singularity hub](https://singularity-hub.org/)
-  inne mniej ciekawe:
   + https://quay.io/
   + https://ngc.nvidia.com/catalog/all?orderBy=modifiedDESC&pageNumber=3&query=&quickFilter=&filters=
   + https://biocontainers.pro/#/registry

Pobieramy za pomocą komend:
- `singularity pull library://<nazwa>` - pobierz obraz \*.sif; np.: `singularity pull library://godlovedc/funny/lolcow` (można pobrać ten obraz do testów)
- `singularity pull docker://godlovedc/lolcow` j.w., automatycznie konwertuje 



### <a name="run">Uruchamianie kontenerów</a>

- `singularity shell <plik obrazu>` - uruchom shell w kontenerze; plikiem obrazu zazwyczaj może być też `library://` `doker://` itp. zamiast ścieżki
- `singularity exec $HOME/lolcow_latest.sif cowsay 'How did you get out of the container?'` - wykonaj (`exec`) komendę w kontenerze
- `singularity run <plik_obrazu>` - uruchom kontener, co jest równoznaczne z uruchomieniem pliku `runscript` zapisanego w kontenerze. Można podejrzeć ten plik za pomocą: `singularity inspect --runscript lolcow_latest.sif`, ALE:
- można również robić tak: `./lolcow_latest.sif`!

Singulairty chce zatrzeć granicę między kontenerem, a hostem, tak aby uruchamianie kontenera było tak jak uruchamianie zwykłego programu. Dlatego, np.:

- ```singularity exec lolcow_latest.sif cowsay moo > cowsaid``` tworzy plik w bierzącym katalogu **poza** kontenerem

- `cat cowsaid | singularity exec lolcow_latest.sif cowsay -n` - pipe **do** kontenera (`-n` oznacza _Disables word wrap_ - nieistotne)
- `singularity exec lolcow_latest.sif sh -c "fortune | cowsay | lolcat"` - pipe'y wewnątrz kontenera (cudzysłów, aby uniknąć inerpretacji komendy przez shell hosta) - invokes a new shell, but inside the container, and tells it to run the single command line `fortune | cowsay | lolcat`


### <a name="build">Budowanie kontenerów</a>

Więcej na ten temat [tutaj](https://singularity-tutorial.github.io/03-building/).
> this is an important concept in Singularity. If you enter a container without root privileges, you are unable to obtain root privileges within the container.


### <a name="tags">Tagi i konwencje nazewnicze</a>
Obrazy są tagowane:
`singularity pull library://debian:9` - tagiem jest `9`.

Tag nie jest przypisany na stałe do konkretnego obrazu, dlatego jeżeli chcemy zawsze dostać ten sam kontener robimy pull by hash: `singularity pull docker://debian@sha256:f17410575376cc2ad0f6f172699ee825a51588f54f6d72bbfeef6e2fa9a57e2f`

`singularity pull library://debian` rozwija się do: `singularity pull library://library/default/debian:latest` Stąd `singularity pull library://lolcow` zwróci błąd, należy zapisać: `singularity pull library://godlovedc/funny/lolcow`, czyli `library://<entity>/<collection>/<container>`.

Podobnie dla dockera `singularity pull docker://godlovedc/lolcow` -> `singularity pull docker://index.docker.io/godlovedc/lolcow:latest`, gdzie `index.docker.io` to _registry_.


### <a name="safety">Bezpieczeństwo</a>
Bezpieczeństwo uruchamiania kontenera z internetu. Mechanizmy m.in.: trusted containers, certified images, signed images by authors etc.


### <a name="bind">Podpinanie katalogów</a>
<pre>
[hpc][user@p2284 dir]$ singularity shell bwa_latest.sif
Singularity> touch touch-in-sing
Singularity> exit
[hpc][user@p2284 dir]$ ls $HOME
lolcow_latest.sif  script.sh  <b>touch-in-sing</b>
</pre>
Dlaczego? There are several special directories that Singularity bind mounts into your container by default. These include: `$HOME`, `/tmp`, `/proc`, `/sys`, `/dev`.

Podpinanie innych folderów: `singularity shell --bind src1:dest1,src2:dest2,src3:dest3 some.sif`.

Dwukropek nie jest potrzebny, bez niego ścieżka w kontenerze będzie taka sama jak poza. Można również: `export SINGULARITY_BINDPATH=src1:dest1,src2:dest2,src3:dest3`.



### <a name="instances">Long-running Instances</a>

- `singularity instance start lolcow.sif <unikalna nazwa>` - uruchamianie w tle (w tutorialu było `instance.start`, ale na prometheusu nie dziala z kropką)
- `singularity shell instance://<unikalna nazwa jw>` - podpięcie się z powrotem do poprzedniej instancji
- `singularity instance stop <nazwa>` - zatrzymianie, (`--all`) zatrzymanie wszystkich.
- `singularity instance list` - wylistowanie instanacji uruchomionych



### <a name="fakeinstall">[Faking a Native Installation within a Singularity Container](https://singularity-tutorial.github.io/07-fake-installation/)</a>
Ogólnie tworzymy skrypty, które uruchamiają kontener (`exec`) z interesującymi nas komendami, a następnie podpinamy je pod nasz `PATH`. Wtedy możemy korzystać z kontenerów dokładnie tak samo jakby program był zainstalowany.
Poniżej `cowsay moo` to spryny skrót (`cowsay` program w `PATH`ie, `moo` to argument) do tego co jest w linijce running (poniżej). Ponadto naturalnie działają pipe'y i przekierowania.
```
$ cowsay moo
running: singularity exec /home/student/lolcow/libexec/lolcow.sif cowsay moo
 _____
< moo >
 -----
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```


### <a name="misc">Misc</a>
> Some programs need root privileges to run. These often include services or daemons that start via the `init.d` or `system.d` systems and run in the background. For instance, `sshd` the `ssh` daemon that listens on port 22 and allows another user to connect to your computer requires root privileges. You will not be able to run it in a container unless you start the container as root.
