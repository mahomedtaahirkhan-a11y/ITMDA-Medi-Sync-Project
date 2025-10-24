/// A data model representing the patient's real-time status in the queue.
class QueueStatusModel {
  final String queueId;
  final int position;
  final int estimatedWaitMinutes;

  QueueStatusModel({
    required this.queueId,
    required this.position,
    required this.estimatedWaitMinutes,
  });
}
