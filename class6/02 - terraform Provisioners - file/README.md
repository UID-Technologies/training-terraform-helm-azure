# What are Terraform Provisioners?

Provisioners in Tearrform are used to execute scripts or commands on resources after they are created or before they are destroyed. they act as a last-mile configuration tools when infrastructure-level provisoning alone is not enough.

They should be used sparingly, since terraform philosopy is to prefere declarative infrastructure.
Provisioners are often seen as a sscape hatch when providers or configuration management tools (like ansible, chef, puppet) cannot handle a use case.

----

## Type of Provisioners
1. `remote-exec` - Runs commands on the remote VM / instance after creation.
2. `local-exec` - Runs commands on the machine where terraform is executed
3. `file` - Uploads files or directories to remote resources
----

## Real-World Use Cases of Provisioners
1. **Bootstrap Application** - Install web servers, DB clients, monitoring agens etc after VM creation.
2. **Push Config Files** - Send .`env`, app congigs, or TLS certificates to instance
3. **Run Local Deployment Task** - Execite Ci/Cd scripts, API calls, or Ansible playbooks form your local machine
4. **Trigger External Systems** - Example: notify Slack, send email, or call a REST API once infra is ready
5. **Clean-up Before Destroy** - Run cleanup scripts or deregister resources before terraform destroys them.

---


## Best Practice
- Use provisioners only when there no native terraform resource avaiable.
- Prefer cloud-init, Packer images or Ansible for complex configurations
- Treat them as a last resort, not a primary configuration tool.