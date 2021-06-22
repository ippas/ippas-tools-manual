
## Uruchamianie zadań

Do uruchamiania zadań w SLURM służą zasadniczo dwie komendy `srun` i `sbatch`. Nie do końca rozumem techniczną różnicę między nimi, natomiast w praktyce pozwalają na różne rzeczy:
* sbatch:
  * umożliwia uruchamianie _job arrays_
  * może zawierać wiele komend `srun` (w przeciwieństwie do `srun`, które nie może mieć innych `srun`)
  * może uruchamiać tylko skrypty
* srun: 
  * komenda `sstat -j <jobID>` wyświetla statystyki aktualnie wykonywanego zadania (dla `sbatch` nie działa)
  * może uruchamiać skrypty i pojedyncze funkcje
  * przydatna do interaktywnych zadań `srun -A <grant> -p <partycja> --pty /bin/bash`

Ogólnie przyjąłem zasadę (wydaje się słuszna), że dla każdego zadania tworzę skrypt uruchamiany przez `sbatch`, który zawiera kluczowe komendy odpalane za pomocą `srun`.

### Opcje i parametry komend `sbatch` i `srun`
Argument | Opis
------- | ----
-N (--nodes=) | liczba węzłów, czyli osobnych "serwerów"/maszyn, węzły nie dzielą miedzy sobą pamięci, ani się ze sobą nie komunikuję (zasadniczo, MPI(?))
-n (--ntasks=) | liczba procesów, nie widzę sensu dla nas w tej opcji; na razie rozumiem ją tylko jako kolejna warstwa abstrakcji do organizacji zadań; być może jest przydatna razem z komendą `parallel` (moduł dostępny na prometheus), np: `find . -name "*jpeg" | parallel -I% --max-args 1 convert % %.png`
--ntasks-per-node= | inny sposób na określenie liczby procesów, reszta j.w.
--cpus-per-task= | liczba rdzeni na proces - to nas najbardziej interesuje
--mem-per-cpu= | ilość pamięci na rdzeń
--mem= | ilość pamięci na WĘZEŁ, inny sposób określenia pamięci, niż to co powyżej
-t (--time=) | czas; najmniej można ustawić 1 minutę
-J (--job-name=) |
--mail-type |
--mail-user | bardzo fajna opcja o mailowym informowaniu o stanie zadania, działa tylko na Prometheuszu
-p (--partition=) |
-A |
-o (--output=) |
-e (--error=) |
--exclusive | nie dziel węzła z innymi (nie testowałem jeszcze)

Parametry mogą być podawane przy uruchamianiu `sbatch` np.: `sbatch -N 5 --cpus-per-task=12 script.sh`, w skrypcie (za pomocą `#SBATCH -N 1`), w skrypcie przy komendach `srun`, np.: `srun -N 1 echo "Hello"`. Pierwsza opcja nadpisuje drugą, a trzecia może wykorzystywać zasoby tylko w obrębie tego co było zdefiniowane za pomocą pierwszej lub drugiej opcji.

### Przykłady
1. 
```bash
#!/bin/bash

srun echo "Hello SLURM!"
```
`$ sbatch -A plgjacekh2021a -p plgrid --mem=100MB script.sh`

```
Hello SLURM!
```

2. 
```bash
#!/bin/bash

srun echo "Hello SLURM!"
```
`$ sbatch -A plgjacekh2021a -p plgrid -N 2 --mem=100MB script.sh`

```
Hello SLURM!
Hello SLURM!
```

3. `srun` wykonuje tę samą komendę dwa razy, ponieważ argument `-n 2` został pobrany z wywołania `sbatch`
```bash
#!/bin/bash

srun echo "Hello SLURM!"
```
`$ sbatch -A plgjacekh2021a -p plgrid -n 2 --mem=100MB script.sh`

```
Hello SLURM!
Hello SLURM!
```

4. Zadeklarowaliśmy dwa węzły, a `srun` uruchamiamy na jednym. Ponieważ uruchamiają się one sekwencyjnie wciąż jesteśmy na tym samym węźle.
```bash
#!/bin/bash

srun -N 1 date +"%H:%M:%S"; /bin/hostname; sleep 5
srun -N 1 date +"%H:%M:%S"; /bin/hostname; sleep 5
```
`$ sbatch -A plgjacekh2021a -p plgrid -N 2 --mem=100MB script.sh`

```
11:49:11
n1027-amd.zeus
11:49:16
n1027-amd.zeus
```

5. Ten przykład jest tylko poglądowy, nie jest to dobra metoda do uruchamiania zadań. Pierwszy `srun` uruchamiamy w tle, aby drugi miał czas się uruchomić jeszcze w czasie trwania poprzedniego. SLURM będzie przydzielał zasoby do wyczerpania, natomiast należy mieć na uwadze, aby nie uruchomić wszystkich komend w tle bo wtedy wszystkie one się uruchomią, skrypt zakończy działanie i całe zadanie zostanie zakończone przez SLURM ubijając te zadania w tle.

   Jak można zauważyć poniżej, dwa pierwsze `srun` uruchomiły się na różnych węzłach, a trzeci `srun` musiał poczekać na wolne zasoby. Stworzyłem dodatkowy skrypt `subscript.sh`, ponieważ nie znalazłem sposobu, aby uruchomić kilka komend jedna po drugiej i uruchomić je w tle w jednej linii `srun`.
```bash
#!/bin/bash

date +"%H:%M:%S"
/bin/hostname
sleep 5
```
```bash
#!/bin/bash

srun -N 1 subscript.sh &
srun -N 1 subscript.sh &
srun -N 1 subscript.sh &

# aby zakończyć wszystko poprzednie zadania, poniższy srun używa wszystkich zaalokowanych zasobów
srun -N 2 date +"%H:%M:%S"
```
`$ sbatch -A plgjacekh2021a -p plgrid -N 2 --mem=100MB script.sh`

```
# dwa poniższe zadania uruchamiają się prawie jednocześnie
12:30:19
n1027-amd.zeus
12:30:19
n1031-amd.zeus
# trzecie zadanie musi poczekać na wolne zasoby
srun: Job step creation temporarily disabled, retrying
srun: Job step creation temporarily disabled, retrying
srun: Job step created
12:30:25
n1027-amd.zeus
# ostatnie zadanie dla wszystkich zasobów uruchamia się dwa razy stąd dwie daty
srun: Job step created
12:30:30
12:30:30
```

6. Bardziej poprawny przykład rozwiązania zadania przedstawionego powyżej. Używamy zadań tablicowych. W tym celu korzystamy z argumentu `--array` działającego w stylu `range` z pythona (ale obustronnie domknięty). Wydaje się, że ten argument uruchamia `sbatch` tyle razy, ile mamy indeksów w `array` ze wszystkimi podanymi argumentami w `sbatch` (oczywiście już bez `--array`).

   Każdy taki `sbatch` posiada swoją własną zmienną środowiskową `$SLURM_ARRAY_TASK_ID`, które zawiera numer zadania. Dodatkowo w statystykach takie zadanie posiada `JobID` z przyrostkiem `_x`, gdzie x to indeks. W przeciwieństwie do _job steps_, które są oddzielane od `JobID` kropką.

   Takie zadanie wyprodukuje zestaw 3 plików _out_.

```bash
#!/bin/bash

date +"%H:%M:%S"
/bin/hostname
echo $SLURM_ARRAY_TASK_ID
sleep 5
```
`$ sbatch -A plgjacekh2021a -p plgrid --array=1-3 --mem=100MB script.sh`


```
==> slurm-9474783_1.out <==
15:06:06
n1075-amd.zeus
1

==> slurm-9474783_2.out <==
15:06:06
n1069-amd.zeus
2

==> slurm-9474783_3.out <==
15:06:07
n1069-amd.zeus
3
```

7. W tym przykładzie uruchomimy 7 zadań, po maksymalnie 3 jednocześnie. Każde zadanie będzie miało do dyspozycji 4 rdzenie, a sleep będzie trwał 10 - _array task id_.

   Argument `--array` możemy definiować na kilka sposobów: `=1,2,3,5,8,13`, `=0-10,15`, `=1-7:2` (czyli 1,3,5,7). Aby ograniczyć ilość jednoczesnych zadań dodajemy `%`, czyli: `--array=0-100%5` - uruchom 101 zadań, ale maksymalnie 5 może działać jednocześnie.


```bash
#!/bin/bash

date +"%H:%M:%S"
/bin/hostname
sleep $((10 - $SLURM_ARRAY_TASK_ID))
```
`$ sbatch -A plgjacekh2021a -p plgrid --array=1-7%3 --cpus-per-task=4 --mem=100MB script.sh`


```
==> slurm-9474796_1.out <==
15:18:57
n1031-amd.zeus

==> slurm-9474796_2.out <==
15:18:57
n1031-amd.zeus

==> slurm-9474796_3.out <==
15:18:57
n1031-amd.zeus

==> slurm-9474796_4.out <==
15:19:05
n1031-amd.zeus

==> slurm-9474796_5.out <==
15:19:06
n1031-amd.zeus

==> slurm-9474796_6.out <==
15:19:07
n1031-amd.zeus

==> slurm-9474796_7.out <==
15:19:12
n1031-amd.zeus
```

   Zobaczmy jeszcze na `zeus-jobs`, które uruchamiałem kilka razy w trakcie wykonywania zadanie.

```ID                       Partition        Name     State   Nodes   Cores   Decl. mem        Max. node mem.   Mem. % usage   Eff.   Walltime
--                       ---------        ----     -----   -----   -----   ---------        --------------   ------------   ----   --------
9474796_1           plgrid-testing   script.sh   RUNNING       1       4    100.0MiB   324.0KiB(n1031-amd)           0.3%   0.0%   00:00:08
9474796_2           plgrid-testing   script.sh   RUNNING       1       4    100.0MiB   324.0KiB(n1031-amd)           0.3%   0.0%   00:00:08
9474796_3           plgrid-testing   script.sh   RUNNING       1       4    100.0MiB                    0B           0.0%   0.0%   00:00:08
9474796_[4-7%3]     plgrid-testing   script.sh   PENDING       1    4(4)    100.0MiB                    --             --     --   00:15:00
===============================================================================================================

ID                     Partition        Name       State   Nodes   Cores   Decl. mem        Max. node mem.   Mem. % usage   Eff.   Walltime
--                     ---------        ----       -----   -----   -----   ---------        --------------   ------------   ----   --------
9474796_1         plgrid-testing   script.sh   COMPLETED       1       4    100.0MiB   324.0KiB(n1031-amd)           0.3%   0.2%   00:00:10
9474796_2         plgrid-testing   script.sh   COMPLETED       1       4    100.0MiB   324.0KiB(n1031-amd)           0.3%   0.2%   00:00:09
9474796_3         plgrid-testing   script.sh   COMPLETED       1       4    100.0MiB   324.0KiB(n1031-amd)           0.3%   0.2%   00:00:08
9474796_4         plgrid-testing   script.sh     RUNNING       1       4    100.0MiB   328.0KiB(n1031-amd)           0.3%   0.0%   00:00:05
9474796_5         plgrid-testing   script.sh     RUNNING       1       4    100.0MiB   324.0KiB(n1031-amd)           0.3%   0.0%   00:00:04
9474796_6         plgrid-testing   script.sh     RUNNING       1       4    100.0MiB   328.0KiB(n1031-amd)           0.3%   0.0%   00:00:03
9474796_[7%3]     plgrid-testing   script.sh     PENDING       1    4(4)    100.0MiB                    --             --     --   00:15:00
```

   W kolumnie _Eff._ dostaliśmy wartości ok 1/4 mniejsze niż w poprzednich przykładach (trzeba uwierzyć mi na słowo ;)

## Statystyki

## Czasy wykonania

[Zasoby obliczeniowe (ośrodek, liczba węzłów, procesory, pamięć)](http://www.plgrid.pl/oferta/zasoby_obliczeniowe/opis_zasobow/HPC)

[Ogólne informacje o zasobach (dysk: $HOME, $SCRATCH, $STORAGE; opis partycji: plgrid, plgrid-testing)](https://kdm.cyfronet.pl/portal/Zeus:Podstawy)

[Opis komend slurma](https://kdm.cyfronet.pl/portal/Podstawy:SLURM)

Przydatne komendy https://kdm.cyfronet.pl/portal/Kategoria:Prometheus_-_narz%C4%99dzia

* `pro-fs`, `zeus-fs` - użycie zasobów dyskowych
* `pro-groupdir-fix KATALOG_DO_KOREKCJI` - korekcja uprawnień i grupy plików znajdujących się w katalogu zespołu - naprawią błędy o przekroczeniu quoty
* `pro-jobs`, `pro-jobs-history`, `zeus-jobs`, `zeus-jobs-history` - ładnie pokazane statystyki zadań (np. _efficiency_); aktualne i historyczne; opcja `-d N` -ostatnie N dni

Inne:

Inne:
* `sshare` - pokazuje aktualnie zużycie zasobów w kontekście priorytetu w kolejce. Miejsce w kolejce jest ustalana głównie na podstawie wartości _FairSahre_ i _Job Age_, czyli im mniej wykorzystaliśmy zasóbów i im dłużej czekamy tym mamy wyższy prorytet. W `sshare` mamy informację o _FairShare_: fs = 2^(-EffectvUsage/NormShares) [na podstawie](https://docs.rc.fas.harvard.edu/kb/fairshare/). Ogólnie 1.0 - 0.5 - wykorzystanie poniżej normy, < 0.5 wykorzystanie powyżej normy. Wartość ta spada z czasem, tzn. ciężko obliczenia po dłuższym czasie mają mniejszy wpływ (np co 4tyg ten wpływ spada o połowę).

1. asdf
2. asdf
3. sdfasdf

   1. sdfsdf
asdfsaf


Komendy diagnostyczne

- `sinfo` - lista węzłów (partition, timelimit, #nodes, state) drain - It means no further job will be scheduled on that node, but the currently running jobs will keep running (by contrast with setting the node down which kills all jobs running on the node).
Nodes are often set to that state so that some maintenance operation can take place once all running jobs are finished.

- `sinfo show partition <nazwa partycji>` - właściowści partycji, np: `scontrol show partition plgrid-testing` zwraca:
```
PartitionName=plgrid-testing
   AllowGroups=ldap,plgrid,qcg-dev AllowAccounts=ALL AllowQos=ALL
   AllocNodes=ce01,arc01,zeus,qcg,qcg-zeus Default=NO QoS=plgrid-testing
   DefaultTime=00:15:00 DisableRootJobs=YES ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=2 MaxTime=01:00:00 MinNodes=1 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=n0759-g7x,n0760-g7x,n0761-g7x,n0762-g7x,n0763-g7x,........
   PriorityJobFactor=3000 PriorityTier=1 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=OFF
   State=UP TotalCPUs=4672 TotalNodes=125 SelectTypeParameters=NONE
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED
```
Najistotniejsze jest `DefaultTime` i `MaxTime`, czyli ile czasu może trwać zadanie.

- `scontrol show node <nazwa wezla>`, np.: `scontrol show node n0765-g7x` zwróci:
```
NodeName=n0765-g7x Arch=x86_64 CoresPerSocket=6
   CPUAlloc=0 CPUErr=0 CPUTot=12 CPULoad=1.51
   AvailableFeatures=intel,localfs,r16
   ActiveFeatures=intel,localfs,r16
   Gres=(null)
   NodeAddr=n0765-g7x NodeHostName=n0765-g7x Version=17.02
   OS=Linux RealMemory=18432 AllocMem=0 FreeMem=17607 Sockets=2 Boards=1
   State=IDLE ThreadsPerCore=1 TmpDisk=0 Weight=1 Owner=N/A MCS_label=N/A
   Partitions=all,plgrid,plgrid-long,plgrid-testing,plgrid-short,grid-plgrid
   BootTime=2021-03-23T14:13:39 SlurmdStartTime=2021-03-23T14:16:18
   CfgTRES=cpu=12,mem=18G
   AllocTRES=
   CapWatts=n/a
   CurrentWatts=0 LowestJoules=0 ConsumedJoules=0
   ExtSensorsJoules=n/s ExtSensorsWatts=0 ExtSensorsTemp=n/s
```
CPUAlloc to zaalokowane cpu. Mamy jeszcze informacje o pamięci.


- `scontrol show job <id zadania>` - szczegóły zdania, np: `scontrol show job 9473317` (state, time, itp)
```
JobId=9473317 JobName=bash
   UserId=plgjacekh(110655) GroupId=plgrid(55000) MCS_label=N/A
   Priority=13015 Nice=0 Account=plgjacekh2021a QOS=plgrid
   JobState=RUNNING Reason=None Dependency=(null)
   Requeue=1 Restarts=0 BatchFlag=0 Reboot=0 ExitCode=0:0
   RunTime=00:00:59 TimeLimit=00:15:00 TimeMin=N/A
   SubmitTime=2021-06-21T13:38:47 EligibleTime=2021-06-21T13:38:47
   StartTime=2021-06-21T13:38:47 EndTime=2021-06-21T13:53:47 Deadline=N/A
   PreemptTime=None SuspendTime=None SecsPreSuspend=0
   Partition=plgrid-testing AllocNode:Sid=zeus:30002
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=n1075-amd
   BatchHost=n1075-amd
   NumNodes=1 NumCPUs=1 NumTasks=1 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   TRES=cpu=1,mem=4G,node=1
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
   MinCPUsNode=1 MinMemoryNode=4G MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   Gres=(null) Reservation=(null)
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=/bin/bash
   WorkDir=/mnt/auto/people/plgjacekh
   Power=
```

[Jupyter na prometheus](https://docs.cyfronet.pl/display/PLGDoc/Python+Jupyter+notebooks+@Prometheus)

##### Dyski
Prometheus






