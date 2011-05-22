Feature: Scp to copy files and directories to and from a remote host
  In order to copy files and directories to/from a bookmarks
  I want to be able to invoke the scp command on these bookmarks.

  Background:
    Given Bookmark "some host1" exist with:
      | name      | value     |
      | host-name | some.host |
    Given Bookmark "some host2" exist with:
      | name      | value      |
      | host-name | some.host2 |
      | login     | mylogin    |
    Given Bookmark "some host3" exist with:
      | name      | value             |
      | host-name | some.host3        |
      | login     | otherlogin        |
      | option    | ForwardAgent=true |

  Scenario: Copy files to server
    When I run the "scp" command with "some host1 -- myfile :remotefile"
    Then It should execute "scp myfile some.host:remotefile"

  Scenario: Copy files from server
    When I run the "scp" command with "some host1 -- :remotefile myfile"
    Then It should execute "scp some.host:remotefile myfile"

  Scenario: Copying directories
    When I run the "scp" command with "-r some host1 -- myfile :remotefile"
    Then It should execute "scp -r myfile some.host:remotefile"

  Scenario: Bookmark with login
    When I run the "scp" command with "some host2 -- :remotefile myfile"
    Then It should execute "scp mylogin@some.host2:remotefile myfile"

  Scenario: Bookmark with ssh options
    When I run the "scp" command with "some host3 -- myfile :remotefile"
    Then It should execute "scp -o ForwardAgent=true myfile otherlogin@some.host3:remotefile"

  Scenario: Scp with bandwidth limit
    When I run the "scp" command with "-l 100 some host1 -- :remotefile myfile"
    Then It should execute "scp -l 100 some.host:remotefile myfile"

  Scenario: scp with full path
    When I run the "scp" command with "some host1 -- :/path/to/remote /path/to/local"
    Then It should execute "scp some.host:/path/to/remote /path/to/local"

  Scenario: scp without indicating remote file
    When I run the "scp" command with "some host1 -- somefile otherfile"
    Then I should get a "The remote path should be prefixed with" error

  Scenario: scp with wrong number of arguments
    When I run the "scp" command with "some host1 -- one two three"
    Then I should get a "Invalid targets: one two three" error

  Scenario: Overriding hostname or login
    When I run the "scp" command with "-n newhost some host2 -- :remote local"
    Then It should execute "scp mylogin@newhost:remote local"
    When I run the "scp" command with "-L otherlogin some host2 -- local :remote"
    Then It should execute "scp local otherlogin@some.host2:remote"
