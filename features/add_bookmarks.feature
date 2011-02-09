Feature: Adding bookmarks
  In order to make it easier to remember all the hosts I have to connect
  I want to be able to store them in a logical way so I can easily retrieve them.

  The bookmarks will be arranged in groups so it'll be easier to navigate
  logically to find a host bookmark. e.g., In order to connect to the mail
  server in the office of a certain customer, I might save this bookmark as:
  customer1 => office => mail_server.

  Scenario: Automatically creating database
    Given No database
    When I bookmark host: "some.host.com" as "group1 somehost"
    Then A database should be created
    And group: "group1 somehost" should point to some.host.com

  Scenario: Automatic database backup
    Given Existing database
    When I bookmark host: "somehost" as "group somehost"
    Then A backup database should be created with ".bak" suffix

  Scenario: Adding host
    When I bookmark host: "somehost" as "group somehost"
    Then group: "group1 somehost" should point to some.host.com

  Scenario: Required hostname
    When I bookmark host: "" as "group somehost"
    Then I should see a "hostname required" error

  Scenario: Overwriting bookmark
    Given Bookmark "group subgroup" exists
    When I bookmark host: "host" as "group subgroup"
    Then I should see a "overwrite" error
