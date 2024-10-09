//
//  Network.swift
//  AniMate
//
//  Created by Sheridan Gomes on 10/2/2024.
//

import Foundation
import Apollo

class Network {
  static let shared = Network()

  private(set) lazy var apollo = ApolloClient(url: URL(string: "https://graphql.anilist.co")!)
}
