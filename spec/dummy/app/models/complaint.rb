# Single table inheritance: complaints live in the `comments` table and point
# at the comment they flag. Exercises folding a subclass into its base class.
class Complaint < Comment
  belongs_to :flagged_comment, class_name: "Comment"
end
