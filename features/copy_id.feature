Feature: Using ssh-copy-id to copy ssh keys to remote host
  In order to be able to login to remote host using key based ssh authentication
  I want to be able to copy my ssh private key to the remote host named by the
  bookmark.

  Scenario: Normal usage (no user info)
    Given Bookmark "some host" exist with:
      | name      | value     |
      | host-name | some.host |
    When I run the "cpid" command with "some host"
    Then It should execute "ssh-copy-id some.host"

  Scenario: Normal usage (with user info)
    Given Bookmark "some host" exist with:
      | name      | value     |
      | host-name | some.host |
      | login     | someone   |
    When I run the "cpid" command with "some host"
    Then It should execute "ssh-copy-id someone@some.host"

  Scenario: Specifying identity
    Given Bookmark "some host" exist with:
      | name      | value     |
      | host-name | some.host |
    When I run the "cpid" command with "-i ~/.ssh/id_dsa some host"
    Then It should execute "ssh-copy-id -i ~/.ssh/id_dsa some.host"
