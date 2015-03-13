#!/usr/bin/python
import argparse
import sys
import os
import time 
import traceback
import sys
import ctypes
import subprocess
from subprocess import Popen, PIPE
import os
from optparse import OptionParser
from biokbase.workspace.client import Workspace
import MySQLdb as mdb

desc1 = '''
NAME
      gwas_GeneList2Networks -- build Networks object from GeneList

SYNOPSIS      
      gwas_GeneList2Networks -u workspace_url -w workspace_id  -i input_object_ID -o output_object_ID -p password 
'''

desc2 = '''
DESCRIPTION
  To speed up network building, this script skip Networks API and directly build Networks typed object (NTO).
  All the data is feteched from KBase workspace and the constructed network output will be stored back to workspace.
'''

desc3 = '''
EXAMPLES
      build internal networks


SEE ALSO
      net-build-internal-networks

AUTHORS

'''

class Node:
    nodes = []
    edges = []
    ugids = {}
    igids = {}
    gid2nt = {}
    clst2genes = {}

    def __init__(self, unodes = [], uedges=[]):
      self._register_nodes(unodes)
      self._register_edges(uedges)
  
    def get_node_id(self, node, nt = "GENE"):
      if not node in self.ugids.keys() :
          #print node + ":" + nt
          self.ugids[node] = len(self.ugids)
          self.nodes.append( {
            'entity_id' : node,
            'name' : node,
            'user_annotations' : {},
            'type' : nt,
            'id' : 'kb|netnode.' + `self.ugids[node]`,
            'properties' : {}
          } )
          self.igids['kb|netnode.' + `self.ugids[node]`] = node
          self.gid2nt[node] = nt
      return "kb|netnode." + `self.ugids[node]`

    def get_node_id(self, node, eid, nt = "GENE"):
      if not node in self.ugids.keys() :
          #print node + ":" + nt
          self.ugids[node] = len(self.ugids)
          self.nodes.append( {
            'entity_id' : node,
            'name' : eid,
            'user_annotations' : {},
            'type' : nt,
            'id' : 'kb|netnode.' + `self.ugids[node]`,
            'properties' : {}
          } )
          self.igids['kb|netnode.' + `self.ugids[node]`] = node
          self.gid2nt[node] = nt
      return "kb|netnode." + `self.ugids[node]`

    def add_edge(self, strength, ds_id, node1, nt1, node2, nt2, confidence):
      #print node1 + "<->" + node2
      self.edges.append( {
          'name' : 'interacting gene pair',
          'properties' : {},
          'strength' : float(strength),
          'dataset_id' : ds_id,
          'directed' : 'false',
          'user_annotations' : {},
          'id' : 'kb|netedge.'+`len(self.edges)`,
          'node_id1' : self.get_node_id(node1, nt1),
          'node_id2' : self.get_node_id(node2, nt2),
          'confidence' : float(confidence)
      })
      if(nt1 == 'CLUSTER'):
        if not node1 in self.clstr2genes.keys() : self.clst2genes[node1] = {}
        if(nt2 == 'GENE'):
          self.clst2gene[node1][node2] = 1
      else:
        if(nt2 == 'CLUSTER'):
          if not node2 in self.clst2genes.keys() : self.clst2genes[node2] = {}
          self.clst2genes[node2][node1] = 1
   
    def add_edge(self, strength, ds_id, node1, nt1, node2, nt2, confidence, eid1, eid2):
      #print node1 + "<->" + node2
      self.edges.append( {
          'name' : 'interacting gene pair',
          'properties' : {},
          'strength' : float(strength),
          'dataset_id' : ds_id,
          'directed' : 'false',
          'user_annotations' : {},
          'id' : 'kb|netedge.'+`len(self.edges)`,
          'node_id1' : self.get_node_id(node1, eid1, nt1),
          'node_id2' : self.get_node_id(node2, eid2, nt2),
          'confidence' : float(confidence)
      })
      if(nt1 == 'CLUSTER'):
        if not node1 in self.clstr2genes.keys() : self.clst2genes[node1] = {}
        if(nt2 == 'GENE'):
          self.clst2gene[node1][node2] = 1
      else:
        if(nt2 == 'CLUSTER'):
          if not node2 in self.clst2genes.keys() : self.clst2genes[node2] = {}
          self.clst2genes[node2][node1] = 1
   
    def _register_nodes(self, unodes):
      self.nodes = unodes
      self.ugids = {}
      for node in self.nodes:
        nnid = node['id']
        nnid = nnid.replace("kb|netnode.","");
        self.ugids[node['entity_id']] = nnid
        self.igids[node['id']] = node['entity_id']
        self.gid2nt[node['entity_id']] = node['type']

    def _register_edges(self, uedges):
      self.edges = uedges
      for edge in self.edges:
        node1 = self.igids[edge['node_id1']];
        nt1  = self.gid2nt[node1];
        node2 = self.igids[edge['node_id2']];
        nt2  = self.gid2nt[node2];
        if(nt1 == 'CLUSTER'):
          if not node1 in self.clstr2genes.keys() : self.clst2genes[node1] = {}
          if(nt2 == 'GENE'):
            self.clst2genes[node1][node2] = 1
        else:
          if(nt2 == 'CLUSTER'):
            if not node2 in self.clst2genes.keys() : self.clst2genes[node2] = {}
            self.clst2genes[node2][node1] = 1
        

    def get_gene_list(self, cnode):
      if(cnode in self.clst2genes.keys()) : return self.clst2genes[cnode].keys()
      return []
     

def gl2networks (args) :
    ###
    # download ws object and convert them to csv
    wsd = Workspace(url=args.ws_url, token=os.environ.get('KB_AUTH_TOKEN'))
    raw_data = wsd.get_object({'id' : args.inobj_id,
                  'workspace' : args.ws_id})['data']

    gl = [ gr[2] for gr in raw_data['genes']]
    gl_str = "'" + "','".join(gl)+ "'"

    
    sql = "SELECT DISTINCT af1.to_link, af2.to_link, f1.source_id, f2.source_id, af1.strength, ig.from_link FROM IsGroupingOf ig, AssociationFeature af1, AssociationFeature af2, Feature f1, Feature f2 WHERE ig.to_link =  af1.from_link and af1.from_link = af2.from_link and (af1.to_link IN ({}) AND af2.to_link IN ({}) ) AND af1.to_link < af2.to_link AND f1.id = af1.to_link AND f2.id = af2.to_link".format(gl_str, gl_str)

    nc = Node()
    datasets = [];

    try:
        con = mdb.connect(args.db_host, args.db_user, args.db_pass, args.db_name);
        cur = con.cursor()
        cur.execute(sql)
    
        edge = cur.fetchone()
        dsid = set()
        while( edge is not None):
            nc.add_edge(edge[4], edge[5], edge[0], 'GENE', edge[1], 'GENE', 0.0, edge[2], edge[3]);
            dsid.add(edge[5]);
            edge = cur.fetchone()
            
        ds_str = "'" + "','".join(dsid)+ "'"
        cur.execute("SELECT id, association_type, data_source, description , df.to_link, sr.from_link FROM AssociationDataset, IsDatasetFor df, IsSourceForAssociationDataset sr WHERE id = df.from_link and id = sr.to_link and id IN({})".format(ds_str))
        ds = cur.fetchone()
        while( ds is not None):
            datasets.append ( { 
                'network_type' : ds[1],
                'taxons' : [ ds[4] ],
                'source_ref' : ds[5],
                'name' : ds[0],
                'id' : ds[0],
                'description' : ds[3],
                'properties' : {
                }
            })
            ds = cur.fetchone()

        # generate Networks object
        net_object = {
          'datasets' : datasets,
          'nodes' : nc.nodes,
          'edges' : nc.edges,
          'user_annotations' : {"genes" :",".join(gl) },
          'name' : 'GeneList Internal Network',
          'id' : args.outobj_id,
          'properties' : {
            'graphType' : 'edu.uci.ics.jung.graph.SparseMultigraph'
          }
        }
 
        # Store results object into workspace
        wsd.save_objects({'workspace' : args.ws_id, 'objects' : [{'type' : 'KBaseNetworks.Network', 'data' : net_object, 'name' : args.outobj_id, 'meta' : {'org_obj_id' : args.inobj_id, 'org_ws_id' : args.ws_id}}]})
        
    except mdb.Error, e:
        print "Error %d: %s" % (e.args[0],e.args[1])
        sys.exit(1)
        
    finally:    
        if con:    
            con.close()

if __name__ == "__main__":
    # Parse options.
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, prog='gwas_GeneList2Networks', epilog=desc3)
    parser.add_argument('-u', '--ws_url', help='Workspace url', action='store', dest='ws_url', default='https://kbase.us/services/ws')
    parser.add_argument('-w', '--ws_id', help='Workspace id', action='store', dest='ws_id', default=None, required=True)
    parser.add_argument('-i', '--in_id', help='Input GeneList object id', action='store', dest='inobj_id', default=None, required=True)
    parser.add_argument('-o', '--out_id', help='Output Network object id', action='store', dest='outobj_id', default=None, required=True)
    parser.add_argument('-d', '--db_host', help='DB Host', action='store', dest='db_host', default='db4.chicago.kbase.us', required=False)
    parser.add_argument('-s', '--db_user', help='DB User', action='store', dest='db_user', default='kbase_sapselect', required=False)
    parser.add_argument('-p', '--db_password', help='DB User', action='store', dest='db_pass', default=None,  required=True)
    parser.add_argument('-n', '--db_name', help='DB Name', action='store', dest='db_name', default='kbase_sapling_v4',  required=False)
    usage = parser.format_usage()
    parser.description = desc1 + '      ' + usage + desc2
    parser.usage = argparse.SUPPRESS
    args = parser.parse_args()


    # main loop
    gl2networks(args)
    exit(0);
