Feature: Updating bookmarks
  In order to modify existing bookmarks
  I want to run runssh update on existing bookmark. This command should fail
  if the bookmark doesn't exist yet (to avoid errors).
  Currently the update command COMPLETELY overwrites the existing bookmark so
  it's not very useful (to be fixed later).

  Scenario: All available options runs successfully
    Given Bookmark "one two three" exist with:
      | name      | value     |
      | host-name | some.host |
      | login     | somelogin |
    When I run the "update" command with "one two three -n some.other.host -l otherlogin -L 8080:localhost:8080"
    Then It should run successfully
    And Bookmark "one two three" should contain:
      | name         | value               |
      | host_name    | some.other.host     |
      | login        | otherlogin          |
      | local_tunnel | 8080:localhost:8080 |

  Scenario: Fails when updating non-existing bookmark
    Given Empty database
    When I run the "update" command with "one two -n somehost"
    Then I should get a "Error: Invalid path!" error
