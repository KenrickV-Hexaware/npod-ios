    //
//  NGPOD.swift
//  NGPOD
//
//  Created by Kenrick Vaz on 10/10/20.
//

import WidgetKit
import SwiftUI
import Intents
import Alamofire
import SwiftyJSON
import Kingfisher

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration, photo: UIImage(named: "widgetDefault")!)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        
        PhotoLoader.fetch { result in
            let commit: SimpleEntry
            if case .success(let fetchedCommit) = result {
                commit = fetchedCommit
            } else {
                commit = SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!)
            }
            let timeline = Timeline(entries: [commit], policy: .after(refreshDate))
            completion(timeline)
        }
        
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let photo: UIImage
}

    struct NGPODEntryView : SwiftUI.View {
    var entry: Provider.Entry

    var body: some SwiftUI.View {
        Image(uiImage: entry.photo).resizable()
            .scaledToFill()
    }
}

@main
struct NGPOD: Widget {
    let kind: String = "NGPOD"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            NGPODEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct NGPOD_Previews: PreviewProvider {
    static var previews: some SwiftUI.View {
        NGPODEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

    struct PhotoLoader {
        
        static func getCacheValue(_ key: String) -> String {
            let userdefaults = UserDefaults.standard
            return userdefaults.string(forKey: key) ?? ""
        }

        static func setCacheValue(_ key: String, value: String) {
            let userdefaults = UserDefaults.standard
            userdefaults.set(value, forKey: key)
        }
        
        static func getCurrentDate() -> String {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: date)
        }
        
        static func fetch(completion: @escaping (Result<SimpleEntry, Error>) -> Void) {
            
            /*
            let currentDate = getCurrentDate()
            
           
            //check cache first
            if(getCacheValue("currentDate") == currentDate) {
                
                downloadImage(getCacheValue("ngpodImage"), completion: completion)
            }
            */
            AF.request("https://ngpod-api.herokuapp.com/api/photo")
                .responseJSON { (response) in
                    
                    let pod = JSON(response.data!)
              
                    if(pod["title"].string == "") {
                        print("SOMETHING IS NOT RIGHT!")
                        completion(.success(SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!)))
                        
                    } else {
                        
                        downloadImage(pod["image"].string!, completion: completion)
                        
                    }
                }
        }
        
        static func downloadImage(_ imageUrl: String, completion: @escaping (Result<SimpleEntry, Error>) -> Void) {
            let url = URL(string: imageUrl)
            
            let downloader = ImageDownloader.default
            downloader.downloadImage(with: url!) { result in
                switch result {
                case .success(let value):
                    print(value.image)
                    setCacheValue("currentDate", value: getCurrentDate())
                    setCacheValue("ngpodImage", value: imageUrl)
                    
                    completion(.success(SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: value.image)))
                case .failure(let error):
                    print(error)
                    completion(.success(SimpleEntry(date: Date(), configuration: ConfigurationIntent(), photo: UIImage(named: "widgetDefault")!)))
                }
            }
        }
    }

    
    
    
