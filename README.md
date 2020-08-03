# Moving Operations to the Cloud - Azure Edition

Terraform code to stand up example full stack web app in Azure with several safeguards. Note that this is far from a secure solution, but just showcasing several cloud-native Azure protections.

## Build Process

1. Install prerequisites:

    - Linux system (tested in WSL2 Ubuntu)
    - Azure CLI tools
    - Terraform 0.12

2. Clone the repository and change into the new directory.

    ```
    git clone https://github.com/ryananicholson/moving-operations.git
    cd moving-operations
    ```
    
3. Log into Azure.

    ```
    az login
    # Follow appropriate steps displayed in terminal
    ```
    
4. Change usernames and passwords as you see fit (replace YOUR-USERNAME-HERE and YOUR-PASSWORD-HERE with your username and password of choice).

    ```
    sed -i 's/student/YOUR-USERNAME-HERE/g' main.tf web-build.sh mgmt-build.sh
    sed -i 's/Security488!/YOUR-PASSWORD-HERE/g' main.tf web-build.sh mgmt-build.sh
    ```

5. Run terraform commands (deployment takes roughly 25 minutes to complete).

    ```
    terraform init
    terraform plan -out tfplan
    terraform apply -auto-approve tfplan
    ```
 
6. View bastion host and web app addresses.

    ```
    cat addresses.txt
    ```
 
7. When finished, destroy environment.

    ```
    terraform destroy -auto-approve
    ```
