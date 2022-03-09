
// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
    custom_runName = workflow.runName
}

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

/*
========================================================================================
    SET UP VARIABLES & VALIDATE INPUTS
========================================================================================
*/

//Create a channel for input read files
if (params.readPaths) {
    if (params.single_end) {
        ch_reads = Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [ file(row[1][0], checkIfExists: true) ] ] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
    } else {
        ch_reads = Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [ file(row[1][0], checkIfExists: true), file(row[1][1], checkIfExists: true) ] ] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
    }
} else {
    ch_reads = Channel
        .fromFilePairs(params.reads, size: params.single_end ? 1 : 2)
        .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nIf this is single-end data, please specify --single_end on the command line." }
}





/*
========================================================================================
    FUNCTIONS
========================================================================================
*/


def nfcoreHeader() {
    // Log colors ANSI codes
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";

    return """    ${c_green}============================================================${c_reset}
            ${c_purple}nf-fastqc v${workflow.manifest.version}${c_reset}
    ${c_green}============================================================${c_reset}
    """.stripIndent()
}

def checkHostname() {
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "============================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}

def helpMessage() {
    log.info nfcoreHeader()
    log.info"""

    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run bioinfo-tsukuba/nf-fastqc --reads '*_R{1,2}.fastq.gz' -profile docker

    Pipeline setting:
      -profile [str]                  Configuration profile to use. Can use multiple (comma separated)
                                      Available: docker, singularity, test, and more
      -c                              Specify the path to a specific config file
      --reads [file]                  Path to input data (must be surrounded with quotes)
      --single_end                    Specifies that the input is single-end reads
      --local_annot_dir [str]         Base path for local annotation files
      --entire_max_cpus [N]            Maximum number of CPUs to use for each step of the pipeline. Should be in form e.g. --entire_max_cpus 16. Default: '${params.entire_max_cpus}'
      --entire_max_memory [str]        Memory limit for each step of pipeline. Should be in form e.g. --entire_max_memory '16.GB'. Default: '${params.entire_max_memory}'  
        
    Other:
      --outdir [str]                  The output directory where the results will be saved
      -name [str]                     Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic
      -resume                         Specify this when restarting a pipeline
      --max_memory [str]              Memory limit for each step of pipeline. Should be in form e.g. --max_memory '8.GB'. Default: '${params.max_memory}'
      --max_time [str]                Time limit for each step of the pipeline. Should be in form e.g. --max_time '2.h'. Default: '${params.max_time}'
      --max_cpus [str]                Maximum number of CPUs to use for each step of the pipeline. Should be in form e.g. --max_cpus 1. Default: '${params.max_cpus}'
      --monochrome_logs               Set to disable colourful command line output and live life in monochrome

    """.stripIndent()
}


/*
========================================================================================
    CREATE WORKFLOW SUMMARY
========================================================================================
*/

// Header log info
log.info nfcoreHeader()

// create summary
def summary = [:]
if (workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Run Name'] = custom_runName ?: workflow.runName
if (!params.readPaths) summary['Reads'] = params.reads
summary['Data Type'] = params.single_end ? 'Single-End' : 'Paired-End'

summary['Resource allocation for the entire workflow']  = "$params.entire_max_cpus cpus, $params.entire_max_memory memory"
summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if (workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"
summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName

summary['Config Profile'] = workflow.profile
if (params.config_profile_description) summary['Config Description'] = params.config_profile_description
if (params.config_profile_contact)     summary['Config Contact']     = params.config_profile_contact
if (params.config_profile_url)         summary['Config URL']         = params.config_profile_url
log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "\033[32m------------------------------------------------------------\033[0m"
log.info "\033[32m------------------------------------------------------------\033[0m"

// Check the hostnames against configured profiles
checkHostname()

Channel.from(summary.collect{ [it.key, it.value] })
    .map { k,v -> "<dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }
    .reduce { a, b -> return [a, b].join("\n            ") }
    .map { x -> """
    id: 'nf-fastqc-summary'
    description: " - this information is collected when the pipeline is started."
    section_name: 'nf-fastqc Workflow Summary'
    section_href: 'https://github.com/bioinfo-tsukuba/nf-fastqc'
    plot_type: 'html'
    data: |
        <dl class=\"dl-horizontal\">
            $x
        </dl>
    """.stripIndent() }
    .set { ch_workflow_summary }

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { FASTQC as FASTQC_RAW } from '../modules/local/fastqc' addParams( options: modules['fastqc'] )

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow FASTQC {
    FASTQC_RAW (
        ch_reads
    ).fastqc_results
    .set { ch_fastqc_results_raw }
}

///////////////////////////////////////////////////////////////////////////////
/*
* workflow.onComplete
*/
///////////////////////////////////////////////////////////////////////////////

workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[nf-fastqc] Successful: " + workflow.runName
    if (!workflow.success) {
        subject = "[nf-fastqc] FAILED: " + workflow.runName
    }
    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if (workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if (workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if (workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

    // On success try attach the multiqc report
    def mqc_report = null
    try {
        if (workflow.success) {
            mqc_report = ch_multiqc_report
            if (mqc_report.getClass() == ArrayList) {
                log.warn "[nf-fastqc] Found multiple reports from process 'multiqc', will use only one"
                mqc_report = mqc_report[0]
            }
        }
    } catch (all) {
        log.warn "[nf-fastqc] Could not attach MultiQC report to summary email"
    }

    // Check if we are only sending emails on failure
    email_address = params.email
    if (!params.email && params.email_on_fail && !workflow.success) {
        email_address = params.email_on_fail
    }

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$projectDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$projectDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: email_address, subject: subject, email_txt: email_txt, email_html: email_html, projectDir: "$projectDir", mqcFile: mqc_report, mqcMaxSize: params.max_multiqc_email_size.toBytes() ]
    def sf = new File("$projectDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (email_address) {
        try {
            if (params.plaintext_email) { throw GroovyException('Send plaintext e-mail, not HTML') }
            // Try to send HTML e-mail using sendmail
            [ 'sendmail', '-t' ].execute() << sendmail_html
            log.info "[nf-fastqc] Sent summary e-mail to $email_address (sendmail)"
        } catch (all) {
            // Catch failures and try with plaintext
            [ 'mail', '-s', subject, email_address ].execute() << email_txt
            log.info "[nf-fastqc] Sent summary e-mail to $email_address (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File("${params.outdir}/pipeline_info/")
    if (!output_d.exists()) {
        output_d.mkdirs()
    }
    def output_hf = new File(output_d, "pipeline_report.html")
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File(output_d, "pipeline_report.txt")
    output_tf.withWriter { w -> w << email_txt }

    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_red = params.monochrome_logs ? '' : "\033[0;31m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";

    if (workflow.stats.ignoredCount > 0 && workflow.success) {
        log.info "-${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}-"
        log.info "-${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCount} ${c_reset}-"
        log.info "-${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCount} ${c_reset}-"
    }

    log.info "${c_green}------------------------------------------------------------${c_reset}"
    log.info "${c_green}------------------------------------------------------------${c_reset}"

    if (workflow.success) {
        log.info "${c_purple}[nf-fastqc]${c_green} Pipeline completed successfully!${c_reset}"
    } else {
        checkHostname()
        log.info "${c_purple}[nf-fastqc]${c_red} Pipeline completed with errors!${c_reset}"
        log.info "${c_purple}[nf-fastqc]${c_red} If you get an error when using nf-fastqc, please refer to the foillowing:${c_reset}"
        log.info "${c_purple}[nf-fastqc]${c_red}    ・https://github.com/bioinfo-tsukuba/nf-fastqc/blob/master/docs/troubleshooting.md ${c_reset}"
        log.info "${c_purple}[nf-fastqc]${c_red}    ・https://nf-co.re/usage/troubleshooting ${c_reset}"
    }
    
    // copy .nextflow.log
    today = new Date().format("yyyy-MM-dd-HH-mm-ss")
    new File("${params.outdir}/nf-fastqc-${today}.log") << new File('.nextflow.log').text
    
    println "${c_purple}[nf-fastqc]${c_green} The log file .nextflow.log was copied to ${params.outdir}/nf-fastqc-${today}.log${c_reset}"
}