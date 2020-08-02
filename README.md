# Moving Operations to the Cloud

Terraform code to stand up example full stack web app in Azure with several safeguards. Note that this is far from a secure solution, but just showcasing several cloud-native Azure protections.

## Build Process

Prerequisites:

- Linux system
- Azure CLI tools
- Terraform 0.12

1. Clone the repository and change into the new directory.

    ```
    git clone https://github.com/ryananicholson/moving-operations.git
    cd moving-operations
    ```
    
2. Log into Azure.

    ```
    az login
    # Follow appropriate steps displayed in terminal
    ```
    
3. Change usernames and passwords as you see fit (replace YOUR-USERNAME-HERE and YOUR-PASSWORD-HERE with your username and password of choice).

    ```
    sed -i 's/student/YOUR-USERNAME-HERE/g' main.tf web-build.sh mgmt-build.sh
    sed -i 's/Security488!/YOUR-PASSWORD-HERE/g' main.tf web-build.sh mgmt-build.sh
    ```

4. Run terraform commands.

    ```
    terraform init
    terraform plan -out tfplan
    terraform apply tfplan -auto-approve
    ```
 
5. View bastion host and web app addresses.

    ```
    cat addresses.txt
    ```
 
6. When finished, destroy environment.

    ```
    terraform destroy -auto-approve
    ```
