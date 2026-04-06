.PHONY: all install-primary install-standby create-buckets enable-crr
.PHONY: backup-now restore-test status failover-test failover-recover

install-primary:
	bash velero/install/velero-install.sh

install-standby:
	bash velero/install/velero-install-standby.sh

create-buckets:
	bash s3/create-buckets.sh

enable-crr:
	bash s3/enable-crr.sh

backup-now:
	velero backup create manual-$(shell date +%Y%m%d%H%M%S) \
	  --include-namespaces='*' --snapshot-volumes --wait \
	  --kubeconfig ~/primary-kubeconfig

restore-test:
	bash restore/restore-test.sh

status:
	@echo '=== PRIMARY ===' && velero backup get --kubeconfig ~/primary-kubeconfig
	@echo '=== STANDBY ===' && velero restore get --kubeconfig ~/standby-kubeconfig
	@echo '=== HEALTH ===' && aws route53 get-health-check-status \
	  --health-check-id cc41f55e-cabb-470f-8c9b-a6d8d9575b59 \
	  --query 'HealthCheckObservations[0].StatusReport.Status' --output text

failover-test:
	aws ec2 stop-instances --region us-east-1 \
	  --instance-ids i-00f7655e0841cc4df
	@echo 'Primary stopped. Monitoring Route53...'

failover-recover:
	aws ec2 start-instances --region us-east-1 \
	  --instance-ids i-00f7655e0841cc4df
	@echo 'Primary restarting...'

 
