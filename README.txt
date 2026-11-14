Guestbook final project

The answers folder already contains the code for Tasks 1, 3, and 8.
The remaining files are recorded from your Skills Network lab session.

1. Upload and unzip the project in your lab. Open a terminal in guestbook.
2. Confirm your IBM Cloud registry namespace with ibmcloud cr namespaces.
   Use the lab's registry login and Kubernetes context before running the commands.
3. Run the following in order. Replace values in uppercase with your lab values.

   export GUESTBOOK_NAMESPACE=YOUR_LAB_NAMESPACE
   bash capture-guestbook.sh v1
   bash capture-guestbook.sh hpa
   bash capture-guestbook.sh scale

   While scale is watching, run the load generator from the lab instructions
   in another terminal. Once the replica count increases, stop the watch with
   Ctrl+C and stop the load generator. Task 4's initial replica count may update
   before it is captured. Inspect the recorded output.

   bash capture-guestbook.sh v2
   bash capture-guestbook.sh cpu CPU_REQUEST CPU_LIMIT
   bash capture-guestbook.sh rollback

   Use the CPU request and limit from your lab. If the lab requires rollback
   to a specific revision, pass its number after rollback.

4. Open answers/ and paste each numbered text file into its matching question.
   Check for a v1 registry row, an increased HPA replica count, the v2 push
   digest, the rollout revision's CPU values, and ReplicaSets after rollback.
