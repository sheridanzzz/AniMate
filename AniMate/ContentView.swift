//
//  ContentView.swift
//  AniMate
//
//  Created by Sheridan Gomes on 9/2/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var isSearchPresented = false
    @State private var myAnimeList: [Anime] = [] // Store added anime
    @State private var selectedAnime: Anime? // Track the selected anime for navigation
    @State private var isNavigationActive = false // Track navigation state

    var body: some View {
        NavigationView {
            VStack {
                List(myAnimeList, id: \.mal_id) { anime in
                    Button(action: {
                        selectedAnime = anime // Set the selected anime
                        isNavigationActive = true // Activate navigation
                    }) {
                        ZStack(alignment: .bottomLeading) {
                            // Background image
                            if let imageUrl = URL(string: anime.images.jpg.image_url) {
                                AsyncImage(url: imageUrl) { image in
                                    image.resizable()
                                         .aspectRatio(contentMode: .fill)
                                         .frame(height: 150) // Adjust height as needed
                                         .clipped() // Ensure the image fits within the frame
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            
                            // Text positioned at the bottom corner
                            VStack(alignment: .leading) {
                                Text(anime.title_english ?? anime.title)
                                    .font(.headline)
                                    .foregroundColor(.white) // Set text color to white
                                if let year = extractYear(from: anime.aired?.from) {
                                    Text("Year: \(String(year))")
                                        .font(.subheadline)
                                        .foregroundColor(.white) // Set text color to white
                                }
                                if let score = anime.score {
                                    Text("Score: \(String(format: "%.1f", score))")
                                        .font(.subheadline)
                                        .foregroundColor(.white) // Set text color to white
                                }
                            }
                            .padding() // Add padding to the text
                            .background(Color.black.opacity(0.5)) // Optional: Add a semi-transparent background for better text readability
                        }
                        .frame(height: 150) // Ensure the ZStack has the same height as the image
                        .shadow(radius: 5) // Add a shadow for a card effect
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove default button styling
                }
                .listStyle(PlainListStyle()) // Use plain list style to reduce padding

                // Hidden NavigationLink for programmatic navigation
                if let selectedAnime = selectedAnime {
                    NavigationLink(
                        destination: EpisodesView(anime: selectedAnime),
                        isActive: $isNavigationActive,
                        label: { EmptyView() }
                    )
                }
            }
            .navigationTitle("AniMate")
            .navigationBarItems(trailing: Button(action: {
                isSearchPresented.toggle()
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $isSearchPresented) {
                SearchView(myAnimeList: $myAnimeList)
            }
        }
    }
}

struct EpisodesView: View {
    let anime: Anime
    @State private var episodes: [Episode] = [] // Store episodes
    @State private var isLoading: Bool = false // Track loading state

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading episodes...")
                    .padding()
            } else {
                List(episodes, id: \.mal_id) { episode in
                    NavigationLink(destination: EpisodeDetailView(animeId: anime.mal_id, episodeNumber: episode.mal_id)) {
                        VStack(alignment: .leading) {
                            Text("\(episode.mal_id). \(episode.title)") // Display episode number and title
                                .font(.headline)
                            if let aired = episode.aired, let formattedDate = formatDate(from: aired) {
                                Text("\(formattedDate)")
                                    .font(.subheadline)
                            }
                            HStack {
                                // Display score as stars
                                if let score = episode.score {
                                    StarRatingView(score: score)
                                }
                                // Display badges for filler and recap
                                if episode.filler {
                                    BadgeView(text: "Filler", color: .red)
                                }
                                if episode.recap {
                                    BadgeView(text: "Recap", color: .blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(anime.title_english ?? anime.title)
        .onAppear {
            fetchEpisodes(for: anime.mal_id)
        }
    }
    
    func fetchEpisodes(for animeId: Int) {
        guard let url = URL(string: "https://api.jikan.moe/v4/anime/\(animeId)/episodes") else {
            print("Invalid URL")
            return
        }
        
        isLoading = true // Start loading
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false } // Stop loading when done
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let episodesResponse = try decoder.decode(EpisodesResponse.self, from: data)
                DispatchQueue.main.async {
                    self.episodes = episodesResponse.data
                }
            } catch {
                print("JSON decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func formatDate(from dateString: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMMM d | yyyy"
            return outputFormatter.string(from: date)
        }
        return nil
    }
}

// Helper view to display star rating
struct StarRatingView: View {
    let score: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: index < Int(score) ? "star.fill" : "star")
                    .foregroundColor(index < Int(score) ? .yellow : .gray)
            }
        }
    }
}

// Helper view to display badges
struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(5)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(5)
    }
}

struct EpisodeVideoResponse: Codable {
    let data: [EpisodeVideo]
}

struct EpisodeVideo: Codable {
    let mal_id: Int
    let title: String
    let episode: String
    let url: String
    let images: EpisodeImage
}

struct EpisodeImage: Codable {
    let jpg: Image2URL
}

struct Image2URL: Codable {
    let image_url: String
}

struct EpisodeDetailResponse: Codable {
    let data: EpisodeDetail
}

struct EpisodeDetail: Codable {
    let mal_id: Int
    let url: String
    let title: String
    let title_japanese: String?
    let title_romanji: String?
    let duration: Int?
    let aired: String?
    let filler: Bool
    let recap: Bool
    let synopsis: String?
}

struct EpisodeDetailView: View {
    let animeId: Int
    let episodeNumber: Int
    @State private var episodeDetail: EpisodeDetail?
    @State private var episodeImageUrl: String?
    @State private var isLoading: Bool = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading episode details...")
                    .padding()
            } else if let detail = episodeDetail {
                VStack(alignment: .leading, spacing: 10) {
                    if let imageUrl = episodeImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                 .aspectRatio(contentMode: .fit)
                                 .frame(height: 200)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    Text("Episode \(episodeNumber): \(detail.title)")
                        .font(.title)
                    if let aired = detail.aired, let formattedDate = formatDetailedDate(from: aired) {
                        Text("Aired: \(formattedDate)")
                            .font(.subheadline)
                    }
                    if let synopsis = detail.synopsis {
                        Text("Synopsis: \(synopsis)")
                            .font(.body)
                    }
                }
                .padding()
            } else {
                Text("No details available")
                    .font(.subheadline)
            }
        }
        .navigationTitle("Episode Details")
        .onAppear {
            fetchEpisodeDetail()
            fetchEpisodeImage()
        }
    }
    
    func fetchEpisodeDetail() {
        guard let url = URL(string: "https://api.jikan.moe/v4/anime/\(animeId)/episodes/\(episodeNumber)") else {
            print("Invalid URL")
            return
        }
        
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let episodeDetailResponse = try decoder.decode(EpisodeDetailResponse.self, from: data)
                DispatchQueue.main.async {
                    self.episodeDetail = episodeDetailResponse.data
                }
            } catch {
                print("JSON decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func fetchEpisodeImage() {
        guard let url = URL(string: "https://api.jikan.moe/v4/anime/\(animeId)/videos/episodes") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let episodeVideoResponse = try decoder.decode(EpisodeVideoResponse.self, from: data)
                if let episodeVideo = episodeVideoResponse.data.first(where: { $0.mal_id == episodeNumber }) {
                    DispatchQueue.main.async {
                        self.episodeImageUrl = episodeVideo.images.jpg.image_url
                    }
                }
            } catch {
                print("JSON decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func formatDetailedDate(from dateString: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
            return outputFormatter.string(from: date)
        }
        return nil
    }
}

struct EpisodesResponse: Codable {
    let data: [Episode]
}

struct Episode: Codable {
    let mal_id: Int
    let title: String
    let aired: String?
    let score: Double?
    let filler: Bool
    let recap: Bool
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SearchView: View {
    @Binding var myAnimeList: [Anime]
    @State private var searchText: String = ""
    @State private var searchResults: [Anime] = [] // Store search results
    @State private var isLoading: Bool = false // Track loading state
    @Environment(\.presentationMode) var presentationMode // Access presentation mode

    var body: some View {
        NavigationView {
            VStack {
                // Search bar and cancel button
                HStack {
                    TextField("Add Anime", text: $searchText, onCommit: {
                        fetchAnimeResults(for: searchText)
                    })
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.search) // Use the search button on the keyboard

                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss() // Dismiss the view
                    }
                    .padding(.trailing)
                }
                .padding(.top) // Add padding to the top to keep it stationary

                // Loading indicator
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                }

                // Display search results
                List(searchResults, id: \.mal_id) { anime in
                    HStack(alignment: .center) { // Align items vertically in the center
                        // Image on the left
                        if let imageUrl = URL(string: anime.images.jpg.image_url) {
                            AsyncImage(url: imageUrl) { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fit)
                                     .frame(width: 100, height: 100) // Set width and height for the image
                                     .cornerRadius(8) // Optional: Add corner radius for a rounded effect
                            } placeholder: {
                                ProgressView()
                            }
                        }

                        // Text information
                        VStack(alignment: .leading, spacing: 5) {
                            Text(anime.title_english ?? anime.title)
                                .font(.headline)
                            if let year = extractYear(from: anime.aired?.from) {
                                Text("Year: \(String(year))")
                                    .font(.subheadline)
                            }
                            if let score = anime.score {
                                Text("Score: \(String(format: "%.1f", score))")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.leading, 5) // Add some padding between the image and text

                        Spacer()

                        // Larger plus button
                        Button(action: {
                            addAnimeToList(anime)
                            presentationMode.wrappedValue.dismiss() // Dismiss the view
                        }) {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .frame(width: 30, height: 30) // Increase the size of the plus button
                                .foregroundColor(.blue) // Optional: Change the color of the button
                        }
                        .padding(.trailing, 10) // Add some padding to the right of the button
                    }
                    .padding(.vertical, 5) // Add vertical padding for each list item
                }
            }
        }
    }

    func fetchAnimeResults(for query: String) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.jikan.moe/v4/anime?q=\(encodedQuery)") else {
            print("Invalid URL")
            return
        }
        
        isLoading = true // Start loading
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false } // Stop loading when done
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let searchResults = try decoder.decode(JikanSearchResults.self, from: data)
                DispatchQueue.main.async {
                    self.searchResults = searchResults.data
                }
            } catch {
                print("JSON decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }

    func addAnimeToList(_ anime: Anime) {
        if !myAnimeList.contains(where: { $0.mal_id == anime.mal_id }) {
            myAnimeList.append(anime)
        } else {
            print("Anime already in list: \(anime.title_english ?? anime.title)")
        }
    }
}

// Function to extract year from a date string
func extractYear(from dateString: String?) -> Int? {
    guard let dateString = dateString else { return nil }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // Adjust format as needed
    if let date = dateFormatter.date(from: dateString) {
        let calendar = Calendar.current
        return calendar.component(.year, from: date)
    }
    return nil
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
    let aired: Aired?
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

struct Aired: Codable {
    let from: String?
    let to: String?
}

struct MyAnimeView: View {
    var body: some View {
        Text("Your Anime List")
    }
}
