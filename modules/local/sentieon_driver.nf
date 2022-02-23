process SENTIEON_DRIVER {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(bam), path(bai), path(score), path(score_idx), path(recal_pre), path(recal_post)
    path fasta
    path fai
    path known_dbsnp
    path known_mills
    path known_indels

    output:
    tuple val(meta), path('*.bam')                  , emit: bam          , optional: true
    tuple val(meta), path('*.bai')                  , emit: bai          , optional: true
    tuple val(meta), path('*.vcf.gz')               , emit: vcf          , optional: true
    tuple val(meta), path('*recal_data.table')      , emit: recal_pre    , optional: true
    tuple val(meta), path('*recal_data.table.post') , emit: recal_post   , optional: true
    tuple val(meta), path('*recal.csv')             , emit: recal_csv    , optional: true
    tuple val(meta), path('*mq_metrics.txt')        , emit: metrics_mq   , optional: true
    tuple val(meta), path('*qd_metrics.txt')        , emit: metrics_qd   , optional: true
    tuple val(meta), path('*gc_summary.txt')        , emit: metrics_qc   , optional: true
    tuple val(meta), path('*gc_metrics.txt')        , emit: metrics_gc   , optional: true
    tuple val(meta), path('*aln_metrics.txt')       , emit: metrics_aln  , optional: true
    tuple val(meta), path('*is_metrics.txt')        , emit: metrics_is   , optional: true
    tuple val(meta), path('*dedup_metrics.txt')     , emit: metrics_dedup, optional: true
    tuple val(meta), path('*score.txt')             , emit: score        , optional: true
    tuple val(meta), path('*score.txt.idx')         , emit: score_idx    , optional: true
    path  "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def args2  = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input  = bam ? "-i $bam" : ''
    def ref    = fasta ? "-r $fasta" : ''
    def dbsnp  = known_dbsnp  ? "-k $known_dbsnp" : ''
    def mills  = known_mills  ? "-k $known_mills" : ''
    def indels = known_indels ? "-k $known_indels" : ''
    if (args.contains('--algo Haplotyper')) {
        if (known_dbsnp) {
            dbsnp = ''
            def args_list = args.split('--algo Haplotyper')
            args_list = [ args_list[0] ] + ["--algo Haplotyper -d $known_dbsnp"] + [ args_list[-1] ]
            args = args_list.join(' ')
        }
    }
    """
    sentieon driver \\
        $ref \\
        -t $task.cpus \\
        $input \\
        $dbsnp \\
        $mills \\
        $indels \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sentieon: \$(echo \$(sentieon driver --version 2>&1) | sed -e "s/sentieon-genomics-//g")
    END_VERSIONS
    """
}