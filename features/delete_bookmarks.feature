Feature: Deleting bookmarks
  In order to remove old/invalid host definitions or empty groups
  I want to be able to delete them by specifying the path.
  
  Scenario: Deleting existing host definition
    Given Bookmark "one two three" exists
    When I delete "one two three"
    Then group "one two three" should not exist
