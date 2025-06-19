// import 'package:socket_io_client/socket_io_client.dart' as IO;

// class VideoService {
//   late IO.Socket socket;
//   final String serverUrl;

//   VideoService({required this.serverUrl});

//   void connect() {
//     socket = IO.io(serverUrl, {
//       'transports': ['websocket'],
//       'autoConnect': false,
//     });

//     socket.connect();
//   }

//   void disconnect() {
//     socket.disconnect();
//   }

//   void joinRoom(String roomName) {
//     socket.emit('join_room', roomName);
//   }

//   void sendOffer(String roomName, dynamic offer) {
//     socket.emit('send_connection_offer', {
//       'roomName': roomName,
//       'offer': offer,
//     });
//   }

//   void sendAnswer(String roomName, dynamic answer) {
//     socket.emit('send_answer', {
//       'roomName': roomName,
//       'answer': answer,
//     });
//   }

//   void sendCandidate(String roomName, dynamic candidate) {
//     socket.emit('send_candidate', {
//       'roomName': roomName,
//       'candidate': candidate,
//     });
//   }

//   void onParticipantReady(Function handler) {
//     socket.on('participant_ready', (data) => handler(data));
//   }

//   void onParticipantLeft(Function handler) {
//     socket.on('participant_left', (data) => handler(data));
//   }

//   void onTooManyParticipants(Function handler) {
//     socket.on('too_many_participants', (data) => handler(data));
//   }

//   void onReceiveOffer(Function(dynamic) handler) {
//     socket.on('receive_connection_offer', (data) => handler(data));
//   }

//   void onReceiveAnswer(Function(dynamic) handler) {
//     socket.on('receive_answer', (data) => handler(data));
//   }

//   void onReceiveCandidate(Function(dynamic) handler) {
//     socket.on('receive_candidate', (data) => handler(data));
//   }

//   void dispose() {
//     socket.disconnect();
//     socket.clearListeners();
//   }
// }