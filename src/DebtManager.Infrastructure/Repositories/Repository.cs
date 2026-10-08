using System.Linq.Expressions;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Infrastructure.Repositories;

public class Repository<T> : IRepository<T> where T : class
{
    protected readonly DebtManagerDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public Repository(DebtManagerDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public virtual async Task<T?> GetByIdAsync(object id, CancellationToken ct = default)
    {
        return await _dbSet.FindAsync(new[] { id }, ct);
    }

    public virtual async Task<List<T>> GetAllAsync(CancellationToken ct = default)
    {
        return await _dbSet.ToListAsync(ct);
    }

    public virtual async Task<List<T>> FindAsync(Expression<Func<T, bool>> predicate, CancellationToken ct = default)
    {
        return await _dbSet.Where(predicate).ToListAsync(ct);
    }

    public virtual IQueryable<T> Query()
    {
        return _dbSet.AsQueryable();
    }

    public virtual async Task AddAsync(T entity, CancellationToken ct = default)
    {
        await _dbSet.AddAsync(entity, ct);
    }

    public virtual async Task AddRangeAsync(IEnumerable<T> entities, CancellationToken ct = default)
    {
        await _dbSet.AddRangeAsync(entities, ct);
    }

    public virtual void Update(T entity)
    {
        _dbSet.Update(entity);
    }

    public virtual void Remove(T entity)
    {
        _dbSet.Remove(entity);
    }

    public virtual void RemoveRange(IEnumerable<T> entities)
    {
        _dbSet.RemoveRange(entities);
    }
}
