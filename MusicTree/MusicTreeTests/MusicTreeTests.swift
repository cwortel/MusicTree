import XCTest
@testable import MusicTree

final class MusicTreeTests: XCTestCase {

    func testArtistDecoding() throws {
        let artist = Artist(
            id: "mb-123",
            name: "Quincy Jones",
            sortName: "Jones, Quincy",
            disambiguation: "producer",
            profile: nil,
            imageURL: nil,
            urls: nil,
            source: .musicBrainz
        )
        XCTAssertEqual(artist.name, "Quincy Jones")
        XCTAssertEqual(artist.source, .musicBrainz)
    }

    func testAlbumDecoding() throws {
        let album = Album(
            id: "discogs-456",
            title: "Thriller",
            artistName: "Michael Jackson",
            year: 1982,
            genres: ["Pop", "Funk"],
            styles: nil,
            coverImageURL: nil,
            tracklist: nil,
            credits: nil,
            formats: ["Vinyl"],
            country: "US",
            labels: ["Epic"],
            source: .discogs
        )
        XCTAssertEqual(album.title, "Thriller")
        XCTAssertEqual(album.year, 1982)
        XCTAssertEqual(album.source, .discogs)
    }

    func testCreditIdentity() throws {
        let credit = Credit(name: "Bruce Swedien", role: "Engineer", tracks: "1 to 9")
        XCTAssertEqual(credit.id, "Bruce Swedien-Engineer")
    }
}
