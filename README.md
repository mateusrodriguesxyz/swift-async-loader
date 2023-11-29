```swift

import AsyncLoader

actor RickAndMortyCharacterAvatarLoader: AsyncLoader {
    
    static var shared = RickAndMortyCharacterAvatarLoader()
   
    var values: [Int : AsyncLoaderState<UIImage>] = [:]
        
    func task(for id: Int) -> Task<UIImage?, Never> {
        Task {
                        
            let request = URLRequest(url: URL(string: "https://rickandmortyapi.com/api/character/avatar/\(id).jpeg")!)
            
            if let (data, _) = try? await URLSession.shared.data(for: request) {
                return UIImage(data: data)
            } else {
                return nil
            }
        }
        
    }
    
    func value(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    func data(from value: UIImage) -> Data? {
        return value.jpegData(compressionQuality: 1)
    }
    
}

```
