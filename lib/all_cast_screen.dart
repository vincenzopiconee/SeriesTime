import 'package:flutter/material.dart';
import 'package:seriestime/models/tv_show_details.dart';
import 'models/appdata.dart';

class AllCastScreen extends StatefulWidget {
  final List<Actor> fullCast;
  final String seriesName;

  const AllCastScreen({
    super.key, 
    required this.fullCast, 
    required this.seriesName
  });

  @override
  State<AllCastScreen> createState() => _AllCastScreenState();
}

class _AllCastScreenState extends State<AllCastScreen> {
  final ScrollController _scrollController = ScrollController(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppData.backgroundColor, // Usiamo lo sfondo dell'app
      appBar: AppBar(
        backgroundColor: AppData.primaryColor, // AppBar trasparente/colore sfondo
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppData.whiteColor, 
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Series Cast",
          style: const TextStyle(
            color: AppData.whiteColor, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: Scrollbar(
        controller: _scrollController, 
        thumbVisibility: true,         
        thickness: 8.0,                
        radius: const Radius.circular(10),
        child: GridView.builder(
          controller: _scrollController, 
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            childAspectRatio: 0.47, // Leggermente ridotto per compensare il padding della card
            crossAxisSpacing: 10,
            mainAxisSpacing: 16,
          ),
          itemCount: widget.fullCast.length,
          itemBuilder: (context, index) {
            final actor = widget.fullCast[index];
            
            // --- INIZIO CARD BIANCA ---
            return Container(
              padding: const EdgeInsets.all(4), // Spazio interno
              decoration: BoxDecoration(
                color: AppData.whiteColor, // Sfondo Bianco
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, 
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4, 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8), // Radius interno (8 vs 12 esterno)
                      child: actor.profileUrl != null
                          ? Image.network(
                              actor.profileUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Container(
                              color: Colors.grey[300],
                              width: double.infinity,
                              child: Icon(Icons.person, color: Colors.grey[600], size: 40),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      actor.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppData.primaryColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      actor.characterName,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 4, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
            // --- FINE CARD BIANCA ---
          },
        ),
      ),
    );
  }
}