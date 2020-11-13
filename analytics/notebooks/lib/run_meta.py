# ---------------------------------------------------------------------------------------------
# MIT License
# Copyright (c) 2020, Solace Corporation, Jochen Traunecker (jochen.traunecker@solace.com)
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com)
# ---------------------------------------------------------------------------------------------

from ._util import to_date
from .constants import *
from .perf_error import PerfError

class RunMeta():
    """ RunMeta """
    def __init__(self, metaJson):
        self.run_id = metaJson["meta"]["run_id"]
        self.run_name = metaJson["meta"]["run_name"]
        self.cloud_provider = metaJson["meta"]["cloud_provider"]
        self.infrastructure = metaJson["meta"]["infrastructure"]
        self.ts_run_start = to_date(metaJson["meta"]["run_start_time"], perf_meta_date_ts_pattern)
        self.ts_run_end = to_date(metaJson["meta"]["run_end_time"], perf_meta_date_ts_pattern)
        self.metaJson = metaJson
        self.startPublisherList = self.createStartPublisherList(metaJson)
        self.endPublisherList = self.createEndPublisherList(metaJson)
        self.startConsumerList = self.createStartConsumerList(metaJson)
        self.endConsumerList = self.createEndConsumerList(metaJson)

    def __str__(self):
        return f'[RunMeta: [infrastructure: {self.infrastructure}] [run_id: {self.run_id}] [run_duration: {self.run_duration()}]]'

    def run_duration(self):
        return self.ts_run_end - self.ts_run_start

    def getSolacePubSubInfo(self):
        return self.metaJson["meta"]["solace_pubsub_image"]

    def getEnvRegion(self):
        return self.metaJson["meta"]["env"]["region"]

    def getEnvZone(self):
        return self.metaJson["meta"]["env"]["zone"]

    """ Client Connections """

    def _createClientList(self, name_list, client_list):
        _clientList = []
        for name in name_list:
            for client in client_list:
                if client['clientName'] == name['clientName']:
                    _clientList.append(client)
        return _clientList         

    def createStartPublisherList(self, metaJson):
        nameList = metaJson['meta']['client_connections']['start_test']['publisher_list']
        clientList = metaJson['meta']['client_connections']['start_test']['client_list']
        return self._createClientList(nameList, clientList)

    def createEndPublisherList(self, metaJson):
        nameList = metaJson['meta']['client_connections']['end_test']['publisher_list']
        clientList = metaJson['meta']['client_connections']['end_test']['client_list']
        return self._createClientList(nameList, clientList)

    def createStartConsumerList(self, metaJson):
        nameList = metaJson['meta']['client_connections']['start_test']['consumer_list']
        clientList = metaJson['meta']['client_connections']['start_test']['client_list']
        return self._createClientList(nameList, clientList)

    def createEndConsumerList(self, metaJson):
        nameList = metaJson['meta']['client_connections']['end_test']['consumer_list']
        clientList = metaJson['meta']['client_connections']['end_test']['client_list']
        return self._createClientList(nameList, clientList)

    def getNumClientConnectionsAtStart(self):
        return len(self.getStartTestConsumerList()) + len(self.getStartTestPublisherList())

    def getNumClientConnectionsAtEnd(self):        
        return len(self.getEndTestConsumerList()) + len(self.getEndTestPublisherList()) 

    def getStartTestPublisherList(self):
        return self.startPublisherList

    def getEndTestPublisherList(self):
        return self.endPublisherList

    def getStartTestConsumerList(self):
        return self.startConsumerList

    def getEndTestConsumerList(self):
        return self.endConsumerList

    def _getClientListAggregates(self, client_list):
        aggregates=dict(
            rxDiscardedMsgCount=0,
            rxMsgCount=0,
            txDiscardedMsgCount=0,
            txMsgCount=0,
            averageRxMsgRate=0,
            averageTxMsgRate=0
        )
        for client in client_list:
            aggregates['rxDiscardedMsgCount'] += client['rxDiscardedMsgCount']
            aggregates['rxMsgCount'] += client['dataRxMsgCount']
            aggregates['txDiscardedMsgCount'] += client['txDiscardedMsgCount']
            aggregates['txMsgCount'] += client['dataTxMsgCount']
            aggregates['averageRxMsgRate'] += client['averageRxMsgRate']
            aggregates['averageTxMsgRate'] += client['averageTxMsgRate']

        return aggregates    

    def getPublisherAggregates(self):
        end     = self._getClientListAggregates(self.getEndTestPublisherList())
        start   = self._getClientListAggregates(self.getStartTestPublisherList())
        return dict(
            rxDiscardedMsgCount = end['rxDiscardedMsgCount']   - start['rxDiscardedMsgCount'],
            rxMsgCount          = end['rxMsgCount']            - start['rxMsgCount'],
            txDiscardedMsgCount = end['txDiscardedMsgCount']   - start['txDiscardedMsgCount'],
            txMsgCount          = end['txMsgCount']            - start['txMsgCount'],
            meanRxMsgRate       = end['averageRxMsgRate'],
            meanTxMsgRate       = end['averageTxMsgRate']
        )

    def getConsumerAggregates(self):
        end     = self._getClientListAggregates(self.getEndTestConsumerList())
        start   = self._getClientListAggregates(self.getStartTestConsumerList())
        return dict(
            rxDiscardedMsgCount = end['rxDiscardedMsgCount'] - start['rxDiscardedMsgCount'],
            rxMsgCount          = end['rxMsgCount'] - start['rxMsgCount'],
            txDiscardedMsgCount = end['txDiscardedMsgCount'] - start['txDiscardedMsgCount'],
            txMsgCount          = end['txMsgCount'] - start['txMsgCount'],
            meanRxMsgRate       = end['averageRxMsgRate'],
            meanTxMsgRate       = end['averageTxMsgRate']
        )

    def getConsumerNamesValues4Plotting(self):
        start_list = self.getStartTestConsumerList()
        end_list   = self.getEndTestConsumerList()
        names = []
        values = []
        for consumer_start, consumer_end  in zip(start_list, end_list):
            name=consumer_end['clientName']
            # NOTE: very brittle, assumes the following structure: 
            # sdkperf-load@devel1-consumer-node-1-consumer_2-000001
            # go from the back - user defines infrastructure name
            parts = name.split("-")
            import logging, sys
            logging.debug(f"name={name}")
            logging.debug(f"parts = {parts}")
            node_number = parts[len(parts)-1-2]
            consumer_name = parts[len(parts)-1-1]
            logging.debug(f"node_number={node_number}, consumer_name={consumer_name}")
            names.append(f"node-{node_number}:{consumer_name}")
            val = consumer_end['dataTxMsgCount'] - consumer_start['dataTxMsgCount']
            values.append(val)
        return names, values
    
    def getRunSpecDescription(self):
        return self.metaJson["meta"]["run_spec"]["general"]["description"]
    
    def getRunSpecParamsSampleDurationSecs(self):
        return self.metaJson["meta"]["run_spec"]["params"]["sample_duration_secs"]

    def getRunSpecParamsTotalNumSamples(self):
        return self.metaJson["meta"]["run_spec"]["params"]["total_num_samples"]

    def getRuncSpecLoadIsIncluded(self):
        return self.metaJson["meta"]["run_spec"]["load"]["include"]

    def getRunSpecLoadNumberOfPublishers(self) -> str:
        if not self.getRuncSpecLoadIsIncluded():
            return "n/a"    
        return f'{len(self.metaJson["meta"]["run_spec"]["load"]["publish"]["publishers"]):,}'

    def getRunSpecLoadPublishMsgPayloadSizeBytes(self) -> str:
        if not self.getRuncSpecLoadIsIncluded():
            return "n/a"    
        return f'{int(self.metaJson["meta"]["run_spec"]["load"]["publish"]["msg_payload_size_bytes"]):,}'

    def getRunSpecLoadPublishMsgRatePerSec(self) -> str:
        if not self.getRuncSpecLoadIsIncluded():
            return "n/a"
        return f'{int(self.metaJson["meta"]["run_spec"]["load"]["publish"]["msg_rate_per_second"]):,}'

    def getRunSpecLoadPublishTotalNumberOfTopics(self) -> str:
        if not self.getRuncSpecLoadIsIncluded():
            return "n/a"    
        list = self.metaJson["meta"]["run_spec"]["load"]["publish"]["publishers"]
        num = 0
        for elem in list:
            num += elem["number_of_topics"]
        return f'{num:,}'

    def getRunSpecLoadPublishTotalMsgRatePerSec(self) -> str:
        if not self.getRuncSpecLoadIsIncluded():
            return "n/a"    
        numPublishers = len(self.metaJson["meta"]["run_spec"]["load"]["publish"]["publishers"])
        rate = int(self.metaJson["meta"]["run_spec"]["load"]["publish"]["msg_rate_per_second"])
        return f'{(numPublishers * rate):,}'

    def getRunSpecLoadSubscribeTotalNumberOfConsumers(self):
        if not self.getRuncSpecLoadIsIncluded():
            return "n/a"    
        return len(self.metaJson["meta"]["run_spec"]["load"]["subscribe"]["consumers"])

    def getNodeSpec(self, node): 
        if self.cloud_provider == "azure":
            return f"size: {node['size']}"
        elif self.cloud_provider == "aws":
            return f"type: {node['node_details']['instance_type']}, cores: {node['node_details']['cpu_core_count']}"
        else:    
            return f"ERROR: unknown node spec for cloud_provider:{self.cloud_provider}"

    def getNumBrokerNodes(self):
        return len(self.metaJson["meta"]["nodes"]["broker_nodes"])

    def getBrokerNodeSpec(self):
        node = self.metaJson["meta"]["nodes"]["broker_nodes"][0]
        return self.getNodeSpec(node)

    def getMonitorNodeSpec(self):
        node = self.metaJson["meta"]["nodes"]["latency_nodes"][0]
        return self.getNodeSpec(node)

    def getNumPublisherNodes(self):
        #  -1:NOT_A_HOST
        return len(self.metaJson["meta"]["inventory"]["sdkperf_publishers"]["hosts"])-1

    def getPublisherNodeSpec(self):
        node = self.metaJson["meta"]["nodes"]["publisher_nodes"][0]
        return self.getNodeSpec(node)

    def getNumConsumerNodes(self):
        #  -1:NOT_A_HOST
        return len(self.metaJson["meta"]["inventory"]["sdkperf_consumers"]["hosts"])-1

    def getConsumerNodeSpec(self):
        node = self.metaJson["meta"]["nodes"]["consumer_nodes"][0]
        return self.getNodeSpec(node)

    """ Run Spec General """
    def getRunSpecGeneral(self):
        return self.metaJson["meta"]["run_spec"]["general"]

    """ Monitor Latency """
    def getNumMonitorNodes(self):
        return len(self.metaJson["meta"]["inventory"]["sdkperf_latency"]["hosts"])

    def getRunSpecMonitorLatencyLpm(self):
        if not self.getRuncSpecMonitorLatencyBrokerNodeIsIncluded() and not self.getRuncSpecMonitorLatencyLatencyNodeIsIncluded():
            return "n/a"  
        return self.metaJson["meta"]["run_spec"]["monitors"]["latency"]["lpm"]

    def getRunSpecMonitorLatencyMsgPayloadSizeBytes(self) -> str:
        if not self.getRuncSpecMonitorLatencyBrokerNodeIsIncluded() and not self.getRuncSpecMonitorLatencyLatencyNodeIsIncluded():
            return "n/a"  
        return f'{int(self.metaJson["meta"]["run_spec"]["monitors"]["latency"]["msg_payload_size_bytes"]):,}'

    def getRunSpecMonitorLatencyMsgRatePerSec(self) -> str:
        if not self.getRuncSpecMonitorLatencyBrokerNodeIsIncluded() and not self.getRuncSpecMonitorLatencyLatencyNodeIsIncluded():
            return "n/a"  
        return f'{int(self.metaJson["meta"]["run_spec"]["monitors"]["latency"]["msg_rate_per_second"]):,}'

    """ Monitor Latency Latency Node """
    def getRuncSpecMonitorLatencyLatencyNodeIsIncluded(self):
        return self.metaJson["meta"]["run_spec"]["monitors"]["latency"]["sdkperf_node_to_broker"]["include"]

    """ Monitor Latency Broker Node """
    def getRuncSpecMonitorLatencyBrokerNodeIsIncluded(self):
        return self.metaJson["meta"]["run_spec"]["monitors"]["latency"]["broker_node_to_broker"]["include"]

    """ Monitor Ping """
    def getRuncSpecMonitorPingIsIncluded(self):
        return self.metaJson["meta"]["run_spec"]["monitors"]["ping"]["include"]

    """ Monitor Vpn """
    def getRuncSpecMonitorVpnIsIncluded(self):
        return self.metaJson["meta"]["run_spec"]["monitors"]["vpn_stats"]["include"]

    def getDisplayNameCloudProvider(self):
        if self.cloud_provider == "azure": 
            return "Azure"
        elif self.cloud_provider == "aws":
            return "AWS"
        else:    
            return self.cloud_provider

    def getUseCaseAsMarkdown(self):
        md = f"""
## Use Case: {self.metaJson["meta"]["run_spec"]["general"]["use_case"]["display_name"]} ({self.metaJson["meta"]["run_spec"]["general"]["use_case"]["name"]})

Test Specification: 
{self.getRunSpecGeneral()["test_spec"]["descr"]}.
({self.getRunSpecGeneral()["test_spec"]["name"]})

Cloud Provider: **{self.getDisplayNameCloudProvider()}**
        """
        return md


    def getAsMarkdown(self):
        md = f"""

## Run Settings
* Description: "{self.getRunSpecDescription()}"

|General                    |                                                   | | Infrastructure:           | cloud provider:{self.cloud_provider}                                        |      |   |  
|:--------------------------|:--------------------------------------------------|-|:--------------------------|:----------------------------------------------------------------------------|:-----|:--|
|Run name:                  |{self.run_name}                                    | |{self.infrastructure}      |region: {self.getEnvRegion()}, zone: {self.getEnvZone()}                     |      |   |                                              
|Run Id:                    |{self.run_id}                                      | |Broker Node:               |nodes: {self.getNumBrokerNodes()}<br/>{self.getBrokerNodeSpec()}             |      |   |
|Run Start:                 |{self.ts_run_start}                                | |Load<br/>Publisher Nodes:  |nodes: {self.getNumPublisherNodes()}<br/>{self.getPublisherNodeSpec()}       |      |   |
|Run End:                   |{self.ts_run_end}                                  | |Load<br/>Consumer Nodes:   |nodes: {self.getNumConsumerNodes()} <br/>{self.getConsumerNodeSpec()}        |      |   |
|Run Duration:              |{self.run_duration()}                              | |Monitor Node:              |nodes: {self.getNumMonitorNodes()} <br/>{self.getMonitorNodeSpec()}          |      |   |  
|Sample Duration (secs):    |{self.getRunSpecParamsSampleDurationSecs()}        | |Solace PubSub+             | {self.getSolacePubSubInfo()}                                                |      |   | 
|Number of Samples:         |{self.getRunSpecParamsTotalNumSamples()}           | |                           |                                                                             |      |   | 


|Load|                                                                          | | Monitors   |                              |                                                                 |  
|:--|:--------------------------------------------------------------------------|-|:-----------|:-----------------------------|:----------------------------------------------------------------|
|Included:              |**{self.getRuncSpecLoadIsIncluded()}**                 | |**Latency** |                              |                                                                 |  
|Connections @ start:   |{self.getNumClientConnectionsAtStart()}                | | |Latency Node to Broker Node - included:  |**{self.getRuncSpecMonitorLatencyLatencyNodeIsIncluded()}**      |    
|Connections @ end:     |{self.getNumClientConnectionsAtEnd()}                  | | |Broker Node to Broker Node - included:   |**{self.getRuncSpecMonitorLatencyBrokerNodeIsIncluded()}**       |      
|Publishers:            |{self.getRunSpecLoadNumberOfPublishers()}              | | |Payload (bytes):                         |{self.getRunSpecMonitorLatencyMsgPayloadSizeBytes()}             |      
| - Payload (bytes):    |{self.getRunSpecLoadPublishMsgPayloadSizeBytes()}      | | |Rate (1/sec):                            |{self.getRunSpecMonitorLatencyMsgRatePerSec()}                   |      
| - Rate (1/sec):       |{self.getRunSpecLoadPublishTotalMsgRatePerSec()}       | |**Ping**       | included:                 |**{self.getRuncSpecMonitorPingIsIncluded()}**                    |  
| - Topics:             |{self.getRunSpecLoadPublishTotalNumberOfTopics()}      | |**Broker VPN** | included:                 |**{self.getRuncSpecMonitorVpnIsIncluded()}**                     |  
|Consumers:             |{self.getRunSpecLoadSubscribeTotalNumberOfConsumers()} | |               |                           |                                                                 |   

            """
        return md    

###
# The End.        