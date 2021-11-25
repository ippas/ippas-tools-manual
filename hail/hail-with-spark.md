## Example Hail init

```python
import os
from uuid import uuid4
import hail as hl


spark_master_host = os.environ.get('SPARK_MASTER_HOST')
spark_master_port = os.environ.get('SPARK_MASTER_PORT')
localfs_path = os.environ.get('SCRATCH_LOCAL')

hl.init(
    master=f'spark://{spark_master_host}:{spark_master_port}',
    tmp_dir=os.path.join(localfs_path, 'hail-tmpdir'),
    default_reference='GRCh38',
    spark_conf={'spark.driver.memory': '40G', 'spark.executor.memory': '80G'},
    log=f'/path/to/log/hail-{str(uuid4())}.log',
)
```

## Tips & Hacks

1. W notebooku dobrze jest podawać pełne ścieżki do czytania i zapisywania plików - bez tego Hail może mieć problem z zapisem/odczytem.
