import Foundation

nonisolated struct SmartQuery: Codable, Sendable, Hashable {
    var version = 1
    var filter: SmartPredicate
    var sort: [SortClause] = []
    var limit: Int?
}

nonisolated struct SortClause: Codable, Sendable, Hashable {
    enum Field: String, Codable, Sendable { case dueDate, createdAt, completedAt, priority, title, position }
    enum Order: String, Codable, Sendable { case asc, desc }
    var field: Field
    var order: Order = .asc
}

nonisolated indirect enum SmartPredicate: Codable, Sendable, Hashable {
    case and([SmartPredicate])
    case or([SmartPredicate])
    case not(SmartPredicate)
    case isCompleted(Bool)
    case isFlagged(Bool)
    case isDeleted(Bool)
    case hasDueDate
    case dueOn(DaySpec)
    case dueBefore(DaySpec)
    case dueAfter(DaySpec)
    case dueInRange(start: DaySpec, end: DaySpec)
    case priorityIn([Int])
    case listIdIn([UUID])
    case tagNameIn([String])
    case titleContains(String, caseInsensitive: Bool)

    private enum Op: String, Codable {
        case and, or, not
        case isCompleted, isFlagged, isDeleted
        case hasDueDate
        case dueOn, dueBefore, dueAfter, dueInRange
        case priorityIn, listIdIn, tagNameIn, titleContains
    }

    private enum CodingKeys: String, CodingKey {
        case op, nodes, node, value, day, start, end, values, caseInsensitive
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .and(let nodes):
            try c.encode(Op.and, forKey: .op); try c.encode(nodes, forKey: .nodes)
        case .or(let nodes):
            try c.encode(Op.or, forKey: .op); try c.encode(nodes, forKey: .nodes)
        case .not(let node):
            try c.encode(Op.not, forKey: .op); try c.encode(node, forKey: .node)
        case .isCompleted(let b):
            try c.encode(Op.isCompleted, forKey: .op); try c.encode(b, forKey: .value)
        case .isFlagged(let b):
            try c.encode(Op.isFlagged, forKey: .op); try c.encode(b, forKey: .value)
        case .isDeleted(let b):
            try c.encode(Op.isDeleted, forKey: .op); try c.encode(b, forKey: .value)
        case .hasDueDate:
            try c.encode(Op.hasDueDate, forKey: .op)
        case .dueOn(let d):
            try c.encode(Op.dueOn, forKey: .op); try c.encode(d, forKey: .day)
        case .dueBefore(let d):
            try c.encode(Op.dueBefore, forKey: .op); try c.encode(d, forKey: .day)
        case .dueAfter(let d):
            try c.encode(Op.dueAfter, forKey: .op); try c.encode(d, forKey: .day)
        case .dueInRange(let s, let e):
            try c.encode(Op.dueInRange, forKey: .op); try c.encode(s, forKey: .start); try c.encode(e, forKey: .end)
        case .priorityIn(let v):
            try c.encode(Op.priorityIn, forKey: .op); try c.encode(v, forKey: .values)
        case .listIdIn(let v):
            try c.encode(Op.listIdIn, forKey: .op); try c.encode(v, forKey: .values)
        case .tagNameIn(let v):
            try c.encode(Op.tagNameIn, forKey: .op); try c.encode(v, forKey: .values)
        case .titleContains(let s, let ci):
            try c.encode(Op.titleContains, forKey: .op)
            try c.encode(s, forKey: .value)
            try c.encode(ci, forKey: .caseInsensitive)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let op = try c.decode(Op.self, forKey: .op)
        switch op {
        case .and: self = .and(try c.decode([SmartPredicate].self, forKey: .nodes))
        case .or: self = .or(try c.decode([SmartPredicate].self, forKey: .nodes))
        case .not: self = .not(try c.decode(SmartPredicate.self, forKey: .node))
        case .isCompleted: self = .isCompleted(try c.decode(Bool.self, forKey: .value))
        case .isFlagged: self = .isFlagged(try c.decode(Bool.self, forKey: .value))
        case .isDeleted: self = .isDeleted(try c.decode(Bool.self, forKey: .value))
        case .hasDueDate: self = .hasDueDate
        case .dueOn: self = .dueOn(try c.decode(DaySpec.self, forKey: .day))
        case .dueBefore: self = .dueBefore(try c.decode(DaySpec.self, forKey: .day))
        case .dueAfter: self = .dueAfter(try c.decode(DaySpec.self, forKey: .day))
        case .dueInRange:
            self = .dueInRange(
                start: try c.decode(DaySpec.self, forKey: .start),
                end: try c.decode(DaySpec.self, forKey: .end)
            )
        case .priorityIn: self = .priorityIn(try c.decode([Int].self, forKey: .values))
        case .listIdIn: self = .listIdIn(try c.decode([UUID].self, forKey: .values))
        case .tagNameIn: self = .tagNameIn(try c.decode([String].self, forKey: .values))
        case .titleContains:
            self = .titleContains(
                try c.decode(String.self, forKey: .value),
                caseInsensitive: try c.decodeIfPresent(Bool.self, forKey: .caseInsensitive) ?? true
            )
        }
    }
}

nonisolated enum DaySpec: Codable, Sendable, Hashable {
    case today
    case tomorrow
    case yesterday
    case exact(Date)

    private enum CodingKeys: String, CodingKey { case kind, date }
    private enum Kind: String, Codable { case today, tomorrow, yesterday, exact }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .today: try c.encode(Kind.today, forKey: .kind)
        case .tomorrow: try c.encode(Kind.tomorrow, forKey: .kind)
        case .yesterday: try c.encode(Kind.yesterday, forKey: .kind)
        case .exact(let d):
            try c.encode(Kind.exact, forKey: .kind)
            try c.encode(d, forKey: .date)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .today: self = .today
        case .tomorrow: self = .tomorrow
        case .yesterday: self = .yesterday
        case .exact: self = .exact(try c.decode(Date.self, forKey: .date))
        }
    }
}
