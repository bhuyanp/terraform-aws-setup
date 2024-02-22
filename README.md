#### AWS Private Key

Create if you dont have one already.

```
aws ec2 create-key-pair \
    --key-name my-key-pair \
    --key-type rsa \
    --key-format pem \
    --query "KeyMaterial" \
    --output text > my-key-pair.pem</code>

chmod 400 my-key-pair.pem
```

#### Create TF Alias

```
alias tf=terraform
```

#### Initialize and deploy

```
tf init
tf plan
tf apply
tf destroy
```

#### EC2 in Public Subnet

Upload your pvt key from the local machine. Make sure to change the public IP.

```
sudo scp -i  ./my-key-pair.pem  ./my-key-pair.pem ec2-user@<public ip>:/home/ec2-user

ssh -i "my-key-pair.pem" ec2-user@<public ip>
```

Validate outbound call

```
sudo yum update -y
```

#### Connect to EC2 in Private Subnet

From the public EC2 fire the following command. Make sure to change the private EC2 IP.

```
ssh -i "my-key-pair.pem" ec2-user@<private ip>
```

Validate outbound call

```
sudo yum update -y
```
