#cloud-config

write_files:
  - path: /etc/ssh/sshd_config.d/vouch-ca.conf
    owner: root:root
    permissions: "0644"
    content: |
      TrustedUserCAKeys /etc/ssh/vouch-ca.pub
      AuthorizedPrincipalsFile /etc/ssh/auth_principals/%u
      RevokedKeys /etc/ssh/vouch-revoked-keys
      MaxAuthTries 20

  - path: /etc/ssh/auth_principals/ec2-user
    owner: root:root
    permissions: "0644"
    content: "*"
  - path: /etc/ssh/vouch-revoked-keys
    owner: root:root
    permissions: "0644"
    content: ""

runcmd:
  - >-
    curl --retry 5 --retry-delay 2 -fsSL
    "${vouch_issuer_url}/v1/credentials/ssh/ca"
    | jq -r '.public_key'
    > /etc/ssh/vouch-ca.pub
  - chmod 0644 /etc/ssh/vouch-ca.pub
  - chown root:root /etc/ssh/vouch-ca.pub
  - sshd -t
  - systemctl restart sshd
