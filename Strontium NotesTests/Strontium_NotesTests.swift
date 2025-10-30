//
//  Strontium_NotesTests.swift
//  Strontium NotesTests
//
//  Created by Sriram Ramnath on 29/10/25.
//

import Testing
@testable import Strontium_Notes

struct Strontium_NotesTests {

    @Test func testNoteCreation() async throws {
        let note = Note(
            filePath: "test.md",
            title: "Test Note",
            content: "# Test\n\nThis is a test note with #tag1 and #tag2"
        )
        
        #expect(note.title == "Test Note")
        #expect(note.tags.contains("tag1"))
        #expect(note.tags.contains("tag2"))
    }
    
    @Test func testWikiLinkParsing() async throws {
        let content = "This links to [[Another Note]] and [[Note|Display Text]]"
        let linkResolver = await LinkResolver()
        let sourceID = UUID()
        
        let links = await linkResolver.parseWikiLinks(from: content, sourceNoteID: sourceID)
        
        #expect(links.count == 2)
        #expect(links[0].targetNoteName == "Another Note")
        #expect(links[1].targetNoteName == "Note")
        #expect(links[1].linkText == "Display Text")
    }
    
    @Test func testSearchQuery() async throws {
        let query = SearchQuery(rawQuery: "test tag:important -exclude")
        
        #expect(query.terms.contains("test"))
        #expect(query.tags.contains("important"))
        #expect(query.excludedTerms.contains("exclude"))
    }
    
    @Test func testMarkdownHeaderExtraction() async throws {
        let markdown = """
        # Header 1
        Some text
        ## Header 2
        More text
        ### Header 3
        """
        
        let headers = MarkdownParser.extractHeaders(markdown)
        
        #expect(headers.count == 3)
        #expect(headers[0].level == 1)
        #expect(headers[0].title == "Header 1")
        #expect(headers[1].level == 2)
        #expect(headers[2].level == 3)
    }
    
    @Test func testTaskExtraction() async throws {
        let markdown = """
        - [ ] Incomplete task
        - [x] Complete task
        - [X] Another complete task
        """
        
        let tasks = MarkdownParser.extractTasks(markdown)
        
        #expect(tasks.count == 3)
        #expect(tasks[0].isCompleted == false)
        #expect(tasks[1].isCompleted == true)
        #expect(tasks[2].isCompleted == true)
    }
    
    @Test func testWordCount() async throws {
        let markdown = """
        # Title
        
        This is a test with some words.
        
        ```swift
        let code = "This should not be counted"
        ```
        
        More text here.
        """
        
        let count = MarkdownParser.wordCount(markdown)
        
        #expect(count > 0)
        #expect(count < 20) // Should exclude code block
    }
}
