# -*- coding: utf-8 -*-
import boto3
import logging
import os
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class RDSManager:
    def __init__(self):
        self.rds_client = boto3.client('rds')

    def start(self, rds_cluster_matcher_names):
        for cluster in self.__get_db_clusters(rds_cluster_matcher_names):
            logger.info(f"start {cluster['DBClusterIdentifier']}")
            self.rds_client.start_db_cluster(
                DBClusterIdentifier=cluster['DBClusterIdentifier']
            )

    def stop(self, rds_cluster_matcher_names):
        for cluster in self.__get_db_clusters(rds_cluster_matcher_names):
            if cluster['Status'] == 'Starting':
                self.__wait_for_starting(cluster)
            logger.info(f"stop {cluster['DBClusterIdentifier']}")
            self.rds_client.stop_db_cluster(
                DBClusterIdentifier=cluster['DBClusterIdentifier']
            )

    def __get_db_clusters(self, rds_cluster_matcher_names):
        res = self.rds_client.describe_db_clusters()
        target_clusters = []
        for cluster in res['DBClusters']:
            has_autostart_tag = any(tag.get('Key') == 'autostop' and tag.get('Value') == 'true' for tag in cluster['TagList'])
            is_name_match = any(matcher in cluster['DBClusterIdentifier'] for matcher in rds_cluster_matcher_names)
            if has_autostart_tag or is_name_match:
                target_clusters.append(cluster)
            cluster_ids = [cluster['DBClusterIdentifier'] for cluster in target_clusters]
        logger.info(f'target cluster ids: {str(cluster_ids)}')
        return target_clusters

    def __wait_for_starting(self, cluster):
        status = None
        while status == 'Starting':
            time.sleep(5)
            res = self.rds_client.describe_db_clusters(
                DBClusterIdentifier=cluster['DBClusterIdentifier']
            )
            status = res['DBClusters'][0]['Status']
            logger.info(f'Current DB Cluster status: {status}')


def lambda_handler(event, _context):
    logger.info(f'Event: {str(event)}')
    command = event['command']
    matcher_names = os.environ['DB_MATCHER_NAMES'].split(',')

    rds = RDSManager()
    if command == 'stop':
        rds.stop(matcher_names)
    elif command == 'start':
        rds.start(matcher_names)
    else:
        logger.warn('this event is not allowed')
    logger.info('complete to exec lambda')
