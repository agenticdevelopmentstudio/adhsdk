from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.job_instance_create_options_on_error import JobInstanceCreateOptionsOnError
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.job_instance_create_options_notify import JobInstanceCreateOptionsNotify


T = TypeVar("T", bound="JobInstanceCreateOptions")


@_attrs_define
class JobInstanceCreateOptions:
    """Job options: priority (0 to 90), the default error strategy, and notify.

    Attributes:
        priority (int | Unset):
        on_error (JobInstanceCreateOptionsOnError | Unset):
        notify (JobInstanceCreateOptionsNotify | Unset):
    """

    priority: int | Unset = UNSET
    on_error: JobInstanceCreateOptionsOnError | Unset = UNSET
    notify: JobInstanceCreateOptionsNotify | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        priority = self.priority

        on_error: str | Unset = UNSET
        if not isinstance(self.on_error, Unset):
            on_error = self.on_error.value

        notify: dict[str, Any] | Unset = UNSET
        if not isinstance(self.notify, Unset):
            notify = self.notify.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if priority is not UNSET:
            field_dict["priority"] = priority
        if on_error is not UNSET:
            field_dict["on_error"] = on_error
        if notify is not UNSET:
            field_dict["notify"] = notify

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_instance_create_options_notify import (
            JobInstanceCreateOptionsNotify,
        )

        d = dict(src_dict)
        priority = d.pop("priority", UNSET)

        _on_error = d.pop("on_error", UNSET)
        on_error: JobInstanceCreateOptionsOnError | Unset
        if isinstance(_on_error, Unset):
            on_error = UNSET
        else:
            on_error = JobInstanceCreateOptionsOnError(_on_error)

        _notify = d.pop("notify", UNSET)
        notify: JobInstanceCreateOptionsNotify | Unset
        if isinstance(_notify, Unset):
            notify = UNSET
        else:
            notify = JobInstanceCreateOptionsNotify.from_dict(_notify)

        job_instance_create_options = cls(
            priority=priority,
            on_error=on_error,
            notify=notify,
        )

        job_instance_create_options.additional_properties = d
        return job_instance_create_options

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
