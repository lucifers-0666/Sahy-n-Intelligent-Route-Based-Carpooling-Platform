import React, { useState, useEffect } from 'react';
import { SupportTicketItem } from '../../types/admin';
import { adminApi } from '../../services/api';
import {
  LifeBuoy,
  Search,
  MessageSquare,
  Clock,
  CheckCircle2,
  AlertCircle,
  X,
  Send,
  User,
  Filter,
  RefreshCw,
} from 'lucide-react';

export const TicketsTab: React.FC = () => {
  const [tickets, setTickets] = useState<SupportTicketItem[]>([]);
  const [counts, setCounts] = useState({ open: 0, in_progress: 0, resolved: 0, closed: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Filters & Search
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [priorityFilter, setPriorityFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);

  // Selected ticket for conversation drawer
  const [selectedTicket, setSelectedTicket] = useState<SupportTicketItem | null>(null);
  const [replyMessage, setReplyMessage] = useState('');
  const [replySubmitting, setReplySubmitting] = useState(false);
  const [statusUpdating, setStatusUpdating] = useState(false);

  const fetchTickets = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await adminApi.getTickets({
        status: statusFilter,
        category: categoryFilter,
        priority: priorityFilter,
        search: searchQuery.trim() || undefined,
        page,
        limit: 15,
      });
      setTickets(res.data);
      setCounts(res.counts);
      setTotalPages(res.totalPages);
      setTotal(res.total);
    } catch (err: any) {
      setError(err.message || 'Failed to load support tickets');
      setTickets([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTickets();
  }, [statusFilter, categoryFilter, priorityFilter, page]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    fetchTickets();
  };

  const handleSendReply = async () => {
    if (!selectedTicket || !replyMessage.trim()) return;

    setReplySubmitting(true);
    try {
      const updated = await adminApi.updateTicket(selectedTicket._id, {
        replyMessage: replyMessage.trim(),
      });
      setSelectedTicket(updated);
      setReplyMessage('');
      fetchTickets();
    } catch (err: any) {
      alert(err.message || 'Failed to dispatch reply');
    } finally {
      setReplySubmitting(false);
    }
  };

  const handleStatusChange = async (newStatus: string) => {
    if (!selectedTicket) return;

    setStatusUpdating(true);
    try {
      const updated = await adminApi.updateTicket(selectedTicket._id, {
        status: newStatus,
      });
      setSelectedTicket(updated);
      fetchTickets();
    } catch (err: any) {
      alert(err.message || 'Failed to change ticket status');
    } finally {
      setStatusUpdating(false);
    }
  };

  const getPriorityBadge = (p: string) => {
    switch (p) {
      case 'urgent':
        return <span className="px-2 py-0.5 text-xs font-bold rounded-full bg-red-100 text-red-800 border border-red-200">Urgent</span>;
      case 'high':
        return <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-orange-100 text-orange-800 border border-orange-200">High</span>;
      case 'medium':
        return <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-blue-100 text-blue-800 border border-blue-200">Medium</span>;
      default:
        return <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-gray-100 text-gray-700 border border-gray-200">Low</span>;
    }
  };

  const getStatusBadge = (s: string) => {
    switch (s) {
      case 'open':
        return <span className="px-2.5 py-0.5 text-xs font-bold rounded-full bg-amber-100 text-amber-900 border border-amber-300">Open</span>;
      case 'in_progress':
        return <span className="px-2.5 py-0.5 text-xs font-bold rounded-full bg-blue-100 text-blue-900 border border-blue-300">In Progress</span>;
      case 'resolved':
        return <span className="px-2.5 py-0.5 text-xs font-bold rounded-full bg-emerald-100 text-emerald-900 border border-emerald-300">Resolved</span>;
      case 'closed':
        return <span className="px-2.5 py-0.5 text-xs font-semibold rounded-full bg-gray-100 text-gray-700 border border-gray-300">Closed</span>;
      default:
        return <span className="px-2.5 py-0.5 text-xs font-semibold rounded-full bg-gray-100 text-gray-700">{s}</span>;
    }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Top Banner and KPI Cards */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-extrabold text-textMain tracking-tight">Support Ticket Desk</h2>
          <p className="text-xs text-textMuted mt-0.5">
            Member inquiries, highway corridor support cases, and operational escalations
          </p>
        </div>
        <button
          onClick={fetchTickets}
          className="btn-secondary self-start md:self-auto flex items-center space-x-1.5 text-xs"
        >
          <RefreshCw className="w-3.5 h-3.5" />
          <span>Refresh Queue</span>
        </button>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div
          onClick={() => { setStatusFilter('open'); setPage(1); }}
          className={`card cursor-pointer border-l-4 transition-all ${statusFilter === 'open' ? 'border-amber-500 shadow-md' : 'border-amber-400 hover:border-amber-500'}`}
        >
          <div className="text-[11px] font-semibold text-textMuted uppercase tracking-wider">Open Tickets</div>
          <div className="text-2xl font-extrabold text-amber-900 mt-1">{counts.open}</div>
          <div className="text-xs text-textMuted mt-0.5">Awaiting initial response</div>
        </div>

        <div
          onClick={() => { setStatusFilter('in_progress'); setPage(1); }}
          className={`card cursor-pointer border-l-4 transition-all ${statusFilter === 'in_progress' ? 'border-blue-500 shadow-md' : 'border-blue-400 hover:border-blue-500'}`}
        >
          <div className="text-[11px] font-semibold text-textMuted uppercase tracking-wider">In Progress</div>
          <div className="text-2xl font-extrabold text-blue-900 mt-1">{counts.in_progress}</div>
          <div className="text-xs text-textMuted mt-0.5">Active investigation</div>
        </div>

        <div
          onClick={() => { setStatusFilter('resolved'); setPage(1); }}
          className={`card cursor-pointer border-l-4 transition-all ${statusFilter === 'resolved' ? 'border-emerald-500 shadow-md' : 'border-emerald-400 hover:border-emerald-500'}`}
        >
          <div className="text-[11px] font-semibold text-textMuted uppercase tracking-wider">Resolved</div>
          <div className="text-2xl font-extrabold text-emerald-900 mt-1">{counts.resolved}</div>
          <div className="text-xs text-textMuted mt-0.5">Solution confirmed</div>
        </div>

        <div
          onClick={() => { setStatusFilter('all'); setPage(1); }}
          className={`card cursor-pointer border-l-4 transition-all ${statusFilter === 'all' ? 'border-forest shadow-md' : 'border-gray-300 hover:border-forest'}`}
        >
          <div className="text-[11px] font-semibold text-textMuted uppercase tracking-wider">Total Queue</div>
          <div className="text-2xl font-extrabold text-textMain mt-1">{total}</div>
          <div className="text-xs text-textMuted mt-0.5">All tickets recorded</div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="card p-4 space-y-3">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <form onSubmit={handleSearchSubmit} className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-textMuted" />
            <input
              type="text"
              placeholder="Search by ticket number or subject..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="input pl-9 text-xs w-full"
            />
          </form>

          <div className="flex flex-wrap items-center gap-2">
            <div className="flex items-center space-x-1.5 text-xs text-textMuted">
              <Filter className="w-3.5 h-3.5" />
              <span>Category:</span>
            </div>
            <select
              value={categoryFilter}
              onChange={(e) => { setCategoryFilter(e.target.value); setPage(1); }}
              className="input text-xs py-1.5 px-2.5"
            >
              <option value="all">All Categories</option>
              <option value="ride_issue">Ride Issue</option>
              <option value="payment_inquiry">Payment Inquiry</option>
              <option value="driver_behavior">Driver Behavior</option>
              <option value="technical_bug">Technical Bug</option>
              <option value="account_access">Account Access</option>
              <option value="other">Other</option>
            </select>

            <select
              value={priorityFilter}
              onChange={(e) => { setPriorityFilter(e.target.value); setPage(1); }}
              className="input text-xs py-1.5 px-2.5"
            >
              <option value="all">All Priorities</option>
              <option value="urgent">Urgent</option>
              <option value="high">High</option>
              <option value="medium">Medium</option>
              <option value="low">Low</option>
            </select>

            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
              className="input text-xs py-1.5 px-2.5"
            >
              <option value="all">All Statuses</option>
              <option value="open">Open</option>
              <option value="in_progress">In Progress</option>
              <option value="resolved">Resolved</option>
              <option value="closed">Closed</option>
            </select>
          </div>
        </div>
      </div>

      {/* Tickets Table */}
      {loading ? (
        <div className="space-y-3">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="skeleton h-14 rounded-xl" />
          ))}
        </div>
      ) : error ? (
        <div className="card text-center py-10 space-y-3">
          <AlertCircle className="w-8 h-8 text-amber-600 mx-auto" />
          <div className="text-sm font-semibold text-textMain">{error}</div>
          <button onClick={fetchTickets} className="btn-secondary text-xs">Retry Query</button>
        </div>
      ) : tickets.length === 0 ? (
        <div className="card text-center py-12 space-y-2">
          <LifeBuoy className="w-10 h-10 text-forest mx-auto opacity-70" />
          <div className="text-sm font-bold text-textMain">No support tickets match criteria</div>
          <div className="text-xs text-textMuted">Try modifying search filters or selecting another queue tab.</div>
        </div>
      ) : (
        <div className="card p-0 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-forest-light border-b border-border text-textMuted uppercase font-semibold text-[10px] tracking-wider">
                <tr>
                  <th className="py-3 px-4">Ticket</th>
                  <th className="py-3 px-4">User</th>
                  <th className="py-3 px-4">Category</th>
                  <th className="py-3 px-4">Priority</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4">Last Updated</th>
                  <th className="py-3 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {tickets.map((t) => (
                  <tr key={t._id} className="hover:bg-gray-50/80 transition-colors">
                    <td className="py-3 px-4">
                      <div className="font-extrabold text-forest">{t.ticketNumber}</div>
                      <div className="text-textMain font-medium truncate max-w-xs">{t.subject}</div>
                    </td>
                    <td className="py-3 px-4">
                      <div className="font-semibold text-textMain">{t.user?.name || 'Member'}</div>
                      <div className="text-textMuted text-[11px]">{t.user?.phone || t.user?.email || 'N/A'}</div>
                    </td>
                    <td className="py-3 px-4">
                      <span className="capitalize font-medium text-textMain">
                        {t.category.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="py-3 px-4">{getPriorityBadge(t.priority)}</td>
                    <td className="py-3 px-4">{getStatusBadge(t.status)}</td>
                    <td className="py-3 px-4 text-textMuted">
                      {new Date(t.updatedAt || t.createdAt).toLocaleDateString('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => setSelectedTicket(t)}
                        className="btn-secondary py-1 px-3 text-xs inline-flex items-center space-x-1"
                      >
                        <MessageSquare className="w-3 h-3" />
                        <span>Inspect</span>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-border bg-gray-50/50">
              <div className="text-xs text-textMuted">
                Page {page} of {totalPages} ({total} tickets)
              </div>
              <div className="flex items-center space-x-2">
                <button
                  disabled={page <= 1}
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  className="btn-secondary py-1 px-2.5 text-xs disabled:opacity-40"
                >
                  Previous
                </button>
                <button
                  disabled={page >= totalPages}
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  className="btn-secondary py-1 px-2.5 text-xs disabled:opacity-40"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Ticket Conversation Detail Drawer */}
      {selectedTicket && (
        <div className="fixed inset-0 z-50 flex items-center justify-end bg-black/40 backdrop-blur-sm animate-fade-in">
          <div className="bg-surface w-full max-w-xl h-full shadow-2xl flex flex-col border-l border-border animate-slide-left">
            {/* Header */}
            <div className="p-4 border-b border-border bg-forest-light flex items-center justify-between">
              <div>
                <div className="flex items-center space-x-2">
                  <span className="font-extrabold text-forest text-sm">{selectedTicket.ticketNumber}</span>
                  {getPriorityBadge(selectedTicket.priority)}
                  {getStatusBadge(selectedTicket.status)}
                </div>
                <h3 className="text-base font-bold text-textMain mt-1 line-clamp-1">{selectedTicket.subject}</h3>
              </div>
              <button
                onClick={() => setSelectedTicket(null)}
                className="w-8 h-8 rounded-lg hover:bg-forest/10 flex items-center justify-center text-textMuted"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* User & Context Overview */}
            <div className="p-4 bg-gray-50 border-b border-border grid grid-cols-2 gap-2 text-xs">
              <div>
                <div className="text-textMuted">Member Name:</div>
                <div className="font-semibold text-textMain">{selectedTicket.user?.name || 'Member'}</div>
              </div>
              <div>
                <div className="text-textMuted">Contact:</div>
                <div className="font-semibold text-textMain">{selectedTicket.user?.phone || selectedTicket.user?.email || 'N/A'}</div>
              </div>
              {selectedTicket.booking && (
                <div className="col-span-2 mt-1 p-2 bg-white rounded-lg border border-border">
                  <div className="font-semibold text-forest">Attached Journey Context</div>
                  <div className="text-[11px] text-textMuted">
                    {selectedTicket.booking.pickup?.name} to {selectedTicket.booking.drop?.name} (Status: {selectedTicket.booking.status})
                  </div>
                </div>
              )}
            </div>

            {/* Conversation Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-3">
              {selectedTicket.messages.map((msg, index) => {
                const isAdmin = msg.sender === 'admin';
                return (
                  <div
                    key={index}
                    className={`flex flex-col ${isAdmin ? 'items-end' : 'items-start'}`}
                  >
                    <div className="flex items-center space-x-1.5 mb-1 text-[11px] text-textMuted">
                      <span className="font-semibold text-textMain">{msg.senderName}</span>
                      <span>({isAdmin ? 'Support Specialist' : 'Member'})</span>
                      <span>·</span>
                      <span>
                        {new Date(msg.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                    <div
                      className={`p-3 rounded-2xl max-w-[85%] text-xs leading-relaxed whitespace-pre-wrap ${
                        isAdmin
                          ? 'bg-forest text-white rounded-tr-none'
                          : 'bg-white border border-border text-textMain rounded-tl-none shadow-sm'
                      }`}
                    >
                      {msg.message}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Status Transition Control */}
            <div className="p-3 border-t border-border bg-gray-50 flex items-center justify-between text-xs">
              <span className="font-semibold text-textMuted">Set Status:</span>
              <div className="flex items-center space-x-1.5">
                {(['open', 'in_progress', 'resolved', 'closed'] as const).map((st) => (
                  <button
                    key={st}
                    disabled={statusUpdating || selectedTicket.status === st}
                    onClick={() => handleStatusChange(st)}
                    className={`px-2.5 py-1 rounded-lg text-xs font-semibold capitalize transition-all ${
                      selectedTicket.status === st
                        ? 'bg-forest text-white shadow-sm'
                        : 'bg-white border border-border text-textMuted hover:bg-gray-100'
                    }`}
                  >
                    {st.replace('_', ' ')}
                  </button>
                ))}
              </div>
            </div>

            {/* Reply Input Box */}
            <div className="p-4 border-t border-border bg-surface">
              <div className="flex items-center space-x-2">
                <textarea
                  rows={2}
                  value={replyMessage}
                  onChange={(e) => setReplyMessage(e.target.value)}
                  placeholder="Type official response to member..."
                  className="input text-xs flex-1 resize-none py-2"
                />
                <button
                  disabled={replySubmitting || !replyMessage.trim()}
                  onClick={handleSendReply}
                  className="btn-primary py-2 px-4 flex items-center space-x-1 text-xs self-stretch"
                >
                  <Send className="w-3.5 h-3.5" />
                  <span>Send</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

