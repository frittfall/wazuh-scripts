1. Place the Script

Save your check_login_whitelist.py script in: /var/ossec/active-response/bin/

```
sudo cp ./check_login_whitelist.py /var/ossec/active-response/bin/check_login_whitelist.py
```

Make sure it’s executable:

```
chmod +x /var/ossec/active-response/bin/check_login_whitelist.py
```

2. Define the Active Response in ossec.conf

Add this inside the <active-response> section:

```xml
<active-response>
  <name>check_login_whitelist</name>
  <command>check_login_whitelist.py</command>
  <location>all</location>
  <timeout_allowed>no</timeout_allowed>
</active-response>
```

3. Create a Rule to Trigger the Script

In your custom rules file (e.g., /var/ossec/etc/rules/local_rules.xml):

```xml
<rule id="100103" level="10">
  <decoded_as>json</decoded_as>
  <field name="event_data.Operation">UserLoggedIn</field>
  <field name="geoip.country_name">!Norway</field>
  <description>Login from outside Norway</description>
  <command>check_login_whitelist</command>
</rule>
```
