//////////////////////////////////////////////
// This file is a part of the Serial Monitor 
// device driver source code
// Written by Alex Bessonov, June 1998

#define BOOL int
#define FALSE 0

#define OK_ALLOCATED(obj) \
   ((obj!=(void *)0) && NT_SUCCESS((obj)->m_status))

void * __cdecl operator new(unsigned int nSize, POOL_TYPE iType);
void __cdecl operator delete(void* p);

class CUString 
{ 
private:
    unsigned char m_bType;
public:
    UNICODE_STRING m_String;
    NTSTATUS m_status;
public:
    CUString(int);
    CUString(PWCHAR);
    CUString(int,int);
    ~CUString();
    void Append(UNICODE_STRING *);
    void CUString::CopyTo(CUString *pTarget);
    BOOL operator==(CUString cuArg);
    int inline GetLength() { return m_String.Length; };
    PWCHAR inline GetString() { return m_String.Buffer; };
    void inline SetLength(int i) { m_String.Length = i; };
};

template <class T>
class CDBLinkedList
{
protected:
    LIST_ENTRY head;
    KSPIN_LOCK splock;

public:
    CDBLinkedList()
    {
        InitializeListHead(&head);
        KeInitializeSpinLock(&splock);
    };
    
    BOOLEAN IsEmpty(void) { return IsListEmpty(&head); };
    ~CDBLinkedList()
    {    // if list is still not empty, free all items
        T *p;
        while (p=(T *) ExInterlockedRemoveHeadList(&head,&splock))
        {
            delete CONTAINING_RECORD(p,T,entry);
        }
    };

    void New(T *p)
    {
        ExInterlockedInsertTailList(&head,&(p->entry),&splock);
    };

    void InsertHead(T *p)
    {
        ExInterlockedInsertHeadList(&head,&(p->entry),&splock);
    };

    T *RemoveHead(void)
    {
        T *p=(T *) ExInterlockedRemoveHeadList(&head,&splock);
        if (p)
            p=CONTAINING_RECORD(p,T,entry);
        return p;
    };
    void Remove(T *p)
    {
        RemoveEntryList(&(p->entry));
    };
};
