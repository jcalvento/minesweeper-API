class GameCommand
  UNCOVER = 'uncover'
  RED_FLAG = 'red_flag'
  QUESTION_MARK_FLAG = 'question_mark'
  DELETE_FLAG = 'delete_flag'

  def self.for(action, game, x, y)
    subclass = self.subclasses.detect(
      -> { raise InvalidCommandError.new "Invalid game command '#{action}'"}
    ) { |klass| klass.can_handle? action }

    subclass.new game, x, y
  end

  def can_handle?(_action)
    self.subclass_responsibility
  end

  def initialize(game, x, y)
    @game = game
    @x_position = x
    @y_position = y
  end

  def exec
    self.subclass_responsibility
  end
end

class Uncover < GameCommand
  def self.can_handle?(action)
    action.eql? UNCOVER
  end

  def exec
    @game.uncover_cell @x_position, @y_position
  end
end

class RedFlag < GameCommand
  def self.can_handle?(action)
    action.eql? RED_FLAG
  end

  def exec
    @game.red_flag @x_position, @y_position
  end
end

class QuestionMarkFlag < GameCommand
  def self.can_handle?(action)
    action.eql? QUESTION_MARK_FLAG
  end

  def exec
    @game.question_mark_flag @x_position, @y_position
  end
end

class DeleteFlag < GameCommand
  def self.can_handle?(action)
    action.eql? DELETE_FLAG
  end

  def exec
    @game.delete_flag @x_position, @y_position
  end
end

class InvalidCommandError < RuntimeError; end
