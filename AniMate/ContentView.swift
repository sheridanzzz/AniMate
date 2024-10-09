//
//  ContentView.swift
//  AniMate
//
//  Created by Sheridan Gomes on 9/2/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            MyAnimeView()
                .tabItem {
                    Label("My Anime", systemImage: "list.star")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var searchResults: [Anime] = [] // Store search results
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for Anime", text: $searchText)
                    .padding()
                
                Button("Search") {
                    fetchAnimeResults(for: searchText)
                }
                
                // Display search results
                List(searchResults, id: \.mal_id) { anime in
                    VStack(alignment: .leading) {
                        Text(anime.title)
                        if let imageUrl = URL(string: anime.images.jpg.image_url) {
                            AsyncImage(url: imageUrl) { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fit)
                                     .frame(height: 100)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        Text(anime.url)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        if let score = anime.score {
                            Text("Score: \(score)")
                                .font(.subheadline)
                        }
                        if let synopsis = anime.synopsis {
                            Text(synopsis)
                                .font(.body)
                                .lineLimit(3)
                        }
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
    
    func fetchAnimeResults(for query: String) {
        // Ensure the query is URL encoded
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.jikan.moe/v4/anime?q=\(encodedQuery)") else {
            print("Invalid URL")
            return
        }
        
        // Use URLSession to make the network request
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            // Print the raw JSON data for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            // Decode the JSON response using your custom structs
            do {
                let decoder = JSONDecoder()
                let searchResults = try decoder.decode(JikanSearchResults.self, from: data)
                DispatchQueue.main.async {
                    self.searchResults = searchResults.data
                }
            } catch {
                print("JSON decoding error: \(error.localizedDescription)")
            }
        }.resume() // Don't forget to start the task
    }
}

// Define the structure for the Jikan API response
struct JikanSearchResults: Codable {
    let data: [Anime]
}

struct Anime: Codable {
    let mal_id: Int
    let url: String
    let images: Images
    let title: String
    let title_english: String?
    let title_japanese: String
    let type: String
    let episodes: Int?
    let status: String
    let score: Double?
    let synopsis: String?
    // Add other fields as needed
}

struct Images: Codable {
    let jpg: ImageURL
    let webp: ImageURL
}

struct ImageURL: Codable {
    let image_url: String
    let small_image_url: String
    let large_image_url: String
}

struct MyAnimeView: View {
    var body: some View {
        Text("Your Anime List")
    }
}

// Example of decoding JSON
func fetchAnimeData() {
    let url = URL(string: "https://api.jikan.moe/v4/anime")!
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
            do {
                let searchResults = try JSONDecoder().decode(JikanSearchResults.self, from: data)
                print(searchResults.data) // Use the decoded data
            } catch {
                print("JSON Decoding error: \(error)")
            }
        }
    }.resume()
}
