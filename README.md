1. EC2 Bastion의 IAM-Role 권한으로 k8s handling을 위해서 아래의 절차가 필요.
2. terraform 으로 EKS Cluster를 만들었다면 EC2 IAM-Role에 "$BASTION_PROFILE_NAME" Mapping되어 있음
3. EKS Cluster를 만들면서 사용했던 Secret/Access Key를 임시로 해당 Bastion에 등록
4. "00_aws-auth_configmap.yaml" 파일의 "IAM-ROLE-NAME" 를 "$BASTION_ROLE_NAME" 으로 치환
5. 수정 완료 후 configmap 반영
6. k8s 권한 및 동작 등 확인 후 Secret/Access Key 제거