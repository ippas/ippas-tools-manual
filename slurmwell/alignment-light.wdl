version 1.0

workflow align_fastq {
    input {
        Array[File] left_fastq
        Array[File] right_fastq
        Int index = 0
    }
    
    scatter(index in range(length(left_fastq))) {
        call bwa_mem_sing {
            input:
                index = index,
                fastq_1 = left_fastq[index],
                fastq_2 = right_fastq[index]
        }
    }
    
    call glue_files {
        input:
            numbers = bwa_mem_sing.out_file
    }

    output {
        File out_answer = glue_files.answer
    }
}


task bwa_mem_sing {
    input {
        File fastq_1
        File fastq_2
        Int index
        String info = "info_sing_~{index}"
        String number = "number_~{index}"
    }

    command <<<
        echo $(date) >> ~{info}
        hostname >> ~{info}
        $(gatk --version &>> ~{info}); true  # always give non-zero exit status
        shuf -i 1-100 -n 1 > ~{number}
    >>>

    runtime {
       docker: "intelliseqngs/gatk-4.1.7.0-hg38:1.0.1"
       memory: "1G"
       cpu: "1"
    }

    output {
        File out_file = number
    }
}

task glue_files {
    input {
        Array[File] numbers
    }

    command <<<
        cat ~{sep=' ' numbers} > all_numbers
    >>>

    runtime {
       memory: "0.5G"
       cpu: "1"
    }

    output {
        File answer = "all_numbers"   
    }
}
