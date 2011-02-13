Feature: Deleting bookmarks
  In order to remove old/invalid host definitions or empty groups
  I want to be able to delete them by specifying the path.

  Scenario: Deleting existing host definition
    Given Bookmark "one two three" exists
    When I delete "one two three"
    And I confirm the prompt
    Then It should run successfully
    And group "one two three" should not exist

  Scenario: Approving deletion with -y option
    Given Bookmark "one two three" exists
    When I delete "one two three" with confirmation
    Then It should run successfully
    And group "one two three" should not exist
  
  Scenario: Cancel deletion upon dis-approving confirmation
    Given Bookmark "one two three" exists
    When I delete "one two three"
    And I answer "no" at the prompt
    Then It should run successfully
    And The output should include "canceled"
    And Bookmark "one two three" should exist

  Scenario: Prompting before deleting
    Given Bookmark "one two three" exists
    When I delete "one two three"
    Then I should be prompted with "Are you sure you want to delete"

  Scenario: Displaying error when deleting non-existing bookmarks
    Given Empty database
    When I delete "one two three" with confirmation
    Then I should get a "Invalid path!" error

  Scenario: Deleting empty groups
    Given Bookmark "one two" is an empty group
    When I delete "one two"
    And I confirm the prompt
    Then It should run successfully
    And group "one two" should not exist

  Scenario: Refusing to delete non-empty groups
    Given Bookmark "one two three" exists
    When I delete "one two" with confirmation
    Then I should get a "on-empty group!" error
