# Kamailio Deployment with PostgreSQL

This playbook automates the installation and configuration of **Kamailio SIP Server** with PostgreSQL integration.  
It ensures Kamailio is properly set up, configured, and ready for database initialization.

---

## 📌 Playbook Stages

### 1. Install Kamailio
Installs the Kamailio SIP server and required dependencies on the target system.

### 2. Deploy Kamailio Config
Copies the Kamailio configuration file (`kamailio.cfg`) to `/etc/kamailio/` so the service runs with the desired settings.

### 3. Create Kamailio User Home Directory if Not Exists
Ensures that the `kamailio` system user has a valid home directory, which will be needed for `.pgpass` file and other configurations.

### 4. Configure `.pgpass` for Kamailio User
Creates the `.pgpass` file containing PostgreSQL credentials, allowing Kamailio utilities (like `kamdbctl`) to connect to the database without prompting for a password.

### 5. Set Permissions on `.pgpass` File
Restricts permissions on `.pgpass` to `600`, as required by PostgreSQL for security.  
This ensures only the `kamailio` user can read it.

### 6. Configure `/etc/kamailio/kamctlrc` for PostgreSQL
Configures the `kamctlrc` file to use PostgreSQL as the database backend, setting values like `DBENGINE`, `DBNAME`, `DBUSER`, and `DBPW`.

### 7. Restart Kamailio
Restarts the Kamailio service to apply the new configuration.

---

## 🚀 Final Manual Step

The database schema must be created manually after the above steps complete.  
Run the following command as root (or with sudo):

```bash
kamdbctl create


---
Perfect 👍, you now have Kamailio running and connected to PostgreSQL.
Kamailio itself is not a softphone — it’s a **SIP signaling server / SIP proxy**. Think of it as a router for SIP traffic (VoIP calls, registrations, presence, etc.). To "work with it," you need to interact with it as a SIP service, not like a normal app.

Here’s how you proceed:

---

## 🔑 1. Understand the role of Kamailio

* **Kamailio = SIP Proxy / Registrar / Load Balancer**

  * It does not make calls itself.
  * It sits between SIP clients (softphones, VoIP phones, gateways) and routes SIP messages.
* Common use cases:

  * SIP registrar (where clients register with username/password).
  * SIP proxy (route calls between users, or to another SIP provider).
  * SBC (Session Border Controller).
  * Load balancer for multiple SIP servers (e.g., FreeSWITCH, Asterisk).

---

## 🛠 2. Connect SIP clients

You’ll need SIP endpoints to register with Kamailio:

* Install a softphone like **Linphone**, **Zoiper**, or **MicroSIP**.
* Create SIP accounts in your Kamailio database (table `subscriber` if you’re using `kamdbctl` defaults).
  Example (from `psql`):

  ```sql
  INSERT INTO subscriber (username, domain, password) 
  VALUES ('alice', 'yourdomain.com', 'alicepass');
  INSERT INTO subscriber (username, domain, password) 
  VALUES ('bob', 'yourdomain.com', 'bobpass');
  ```
* Configure the softphone with:

  * **SIP server**: your Kamailio IP (e.g. `sip:102.22.27.147:5060`)
  * **Username/Password**: as created above
  * **Transport**: UDP or TCP (match what Kamailio is listening on)

Now Alice and Bob can register and call each other through Kamailio.

---

## 🔍 3. Monitor and interact with Kamailio

Kamailio provides an **admin CLI tool**:

```bash
kamctl monitor        # show status, active users, load
kamctl ul show        # show registered users (user location)
kamctl fifo list      # interact with runtime commands
```

If you installed with database support:

```bash
kamdbctl list         # show database tables Kamailio uses
```

---

## 📞 4. Make a basic call flow

* Alice registers with Kamailio.
* Bob registers with Kamailio.
* Alice dials Bob’s SIP URI (`sip:bob@yourdomain.com`).
* Kamailio proxies the INVITE to Bob.
* Media (RTP) flows **directly between Alice and Bob** (Kamailio doesn’t handle RTP by default, it just manages signaling).

---

## 🔧 5. Extend with features

Kamailio is highly modular — you enable features in `/etc/kamailio/kamailio.cfg`.

Examples:

* **Auth module**: user authentication with database
* **Usrloc + Registrar**: manage SIP registrations
* **Dispatcher module**: load balancing SIP requests
* **TLS**: secure signaling (SIP over TLS)
* **NAT traversal**: helpful if clients are behind NAT

---

## 🧩 6. Optional: Pair with a media server

Kamailio handles SIP signaling but not media (voice, RTP). If you want IVR, voicemail, conferencing, etc., pair Kamailio with:

* **Asterisk** or **FreeSWITCH** (for call features & media)
* Kamailio stays in front as the SIP load balancer & SBC.

---

✅ So in practice, the first step now is:

1. Add SIP users in the database.
2. Register them with a softphone.
3. Test calls through Kamailio.

Do you want me to give you a **step-by-step to add SIP users in Postgres and test with Zoiper/Linphone softphones** so you can actually place calls through your Kamailio?
