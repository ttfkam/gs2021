export const getDayBeforeAndDayAfter = (date: Date): { pStart: string; pEnd: string } => {
	const yesturday = new Date(date.getTime());
	yesturday.setDate(yesturday.getDate() - 1);
	const tomorrow = new Date(date.getTime());
	tomorrow.setDate(tomorrow.getDate() + 1);
	const pStart = yesturday.toISOString().split('T')[0];
	const pEnd = tomorrow.toISOString().split('T')[0];
	return {
		pStart,
		pEnd
	};
};
