#BEGIN_HEADER
#END_HEADER


class GWAS:
    '''
    Module Name:
    GWAS

    Module Description:
    
    '''

    ######## WARNING FOR GEVENT USERS #######
    # Since asynchronous IO can lead to methods - even the same method -
    # interrupting each other, you must be *very* careful when using global
    # state. A method could easily clobber the state set by another while
    # the latter method is running.
    #########################################
    #BEGIN_CLASS_HEADER
    #END_CLASS_HEADER

    # config contains contents of config file in a hash or None if it couldn't
    # be found
    def __init__(self, config):
        #BEGIN_CONSTRUCTOR
        #END_CONSTRUCTOR
        pass

    def prepare_variation(self, args):
        # self.ctx is set by the wsgi application class
        # return variables are: job_id
        #BEGIN prepare_variation
        #END prepare_variation

        #At some point might do deeper type checking...
        if not isinstance(job_id, list):
            raise ValueError('Method prepare_variation return value ' +
                             'job_id is not type list as required.')
        # return the results
        return [job_id]

    def calculate_kinship_matrix(self, args):
        # self.ctx is set by the wsgi application class
        # return variables are: job_id
        #BEGIN calculate_kinship_matrix
        #END calculate_kinship_matrix

        #At some point might do deeper type checking...
        if not isinstance(job_id, list):
            raise ValueError('Method calculate_kinship_matrix return value ' +
                             'job_id is not type list as required.')
        # return the results
        return [job_id]

    def run_gwas(self, args):
        # self.ctx is set by the wsgi application class
        # return variables are: job_id
        #BEGIN run_gwas
        #END run_gwas

        #At some point might do deeper type checking...
        if not isinstance(job_id, list):
            raise ValueError('Method run_gwas return value ' +
                             'job_id is not type list as required.')
        # return the results
        return [job_id]

    def variations_to_genes(self, args):
        # self.ctx is set by the wsgi application class
        # return variables are: status
        #BEGIN variations_to_genes
        #END variations_to_genes

        #At some point might do deeper type checking...
        if not isinstance(status, list):
            raise ValueError('Method variations_to_genes return value ' +
                             'status is not type list as required.')
        # return the results
        return [status]

    def genelist_to_networks(self, args):
        # self.ctx is set by the wsgi application class
        # return variables are: status
        #BEGIN genelist_to_networks
        #END genelist_to_networks

        #At some point might do deeper type checking...
        if not isinstance(status, list):
            raise ValueError('Method genelist_to_networks return value ' +
                             'status is not type list as required.')
        # return the results
        return [status]
