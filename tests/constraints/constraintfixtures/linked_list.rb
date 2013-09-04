class ListCell
  attr_accessor :value, :next

  def initialize(value, nxt=nil)
    @value = value
    @next = nxt
  end

  def insert_before(new_cell)
    new_cell.next = self
    new_cell
  end

  def insert_after(new_cell)
    @next, new_cell.next = new_cell, @next
    self
  end
end

class DoublyLinkedListCell < ListCell
  attr_accessor :prev

  def initialize(*args)
    super
    this = self # XXX: we don't have constraints on `self'
    # TODO: move the condition into the always. the real test is,
    # whether the condition is always satisfied when the list is
    # modified
    # TODO: readonly annotations need to work with identity
    # constraints, so we can write:
    #   always { @next.prev is? this.? } if @next
    # always { this is? @next.prev } if @next

    # XXX: this is an alternate solution, but this works with the
    # condition, by re-evalutating as needed, and without identity
    # constraints
    # always(solver: nil) do
    #   @next.prev = self if @next
    #   true # have to return true to tell the system that this is
    #        # satisfies the constraint we want
    # end
    always { @next.nil? or (@next.prev is? this) }
  end
end

def cons(*args)
  first = DoublyLinkedListCell.new(args.pop)
  args.reverse.inject(first) do |cell, nxt|
    DoublyLinkedListCell.new(nxt, cell)
  end
end

def it(description, &block)
  raise "it #{description}" unless block.call
end

list = cons 1, 2, 3

it "should have 3 as the value of the last element" do list.next.next.value == 3 end

it "should not have a next element after the last" do list.next.next.next.nil? end

it "should not have a prev element before the first" do list.prev.nil? end

it "should have the previous elements set for the last two elements" do
  list.next.prev == list && list.next.next.prev == list.next
end

it "should have the previous elements set for the last two elements" do
  list.next.prev == list && list.next.next.prev == list.next
end

list = list.insert_before(cons(-1))

it "should start with -1" do list.value == -1 end

it "should have the previous elements set for the last three elements" do
  list.next.prev == list &&
    list.next.next.prev == list.next &&
    list.next.next.next.prev == list.next.next
end

list.insert_after(cons(0))

it "should start with -1" do list.value == -1 end
it "should have 0 as second element" do list.next.value == 0 end

it "should have the previous elements set for the last four elements" do
  list.next.prev == list &&
    list.next.next.prev == list.next &&
    list.next.next.next.prev == list.next.next &&
    list.next.next.next.next.prev == list.next.next.next
end

list = cons(1, 2)
list.next.next = list

it "should be circular" do
  list.next.prev == list && list.prev == list.next
end
