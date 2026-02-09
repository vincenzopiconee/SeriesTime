import 'package:flutter/material.dart';
import 'package:seriestime/models/actor.dart';
import '../models/app_data.dart';

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
      backgroundColor: AppData.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppData.primaryColor,
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
        radius: const Radius.circular(10),
        child: GridView.builder(
          controller: _scrollController, 
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            childAspectRatio: 0.53, 
            crossAxisSpacing: 10,
            mainAxisSpacing: 16,
          ),
          itemCount: widget.fullCast.length,
          itemBuilder: (context, index) {
            final actor = widget.fullCast[index];
            return Container(
              padding: const EdgeInsets.all(4), 
              decoration: BoxDecoration(
                color: AppData.whiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Column(
                children: [
                  SizedBox( 
                        height: 135, 
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: actor.profileUrl != null
                              ? Image.network(actor.profileUrl!, fit: BoxFit.cover)
                              : Container(color: Colors.grey[300], child: const Icon(Icons.person, color: Colors.grey, size: 105)),
                        ),
                      ),

                  const SizedBox(height: 4),
                  
                  Text(
                    actor.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppData.primaryColor),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 4),
                  
                  Text(
                    actor.characterName,
                    maxLines: 4, 
                    overflow: TextOverflow.ellipsis, 
                    style: TextStyle(
                      fontSize: 10, 
                      color: Colors.grey[600],
                      height: 1.1
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}