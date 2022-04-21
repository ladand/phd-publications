import java.util.*;

public class HuffmanComparator implements Comparator<Object>
{
    public int compare(Object a, Object b) {
	Object[] aa = (Object[]) a;
	Object[] bb = (Object[]) b;
	return ((Double)aa[0]).compareTo((Double)bb[0]);
    }
}